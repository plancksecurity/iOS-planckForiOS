//
//  InboxSync.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

public class InboxSync {
    typealias SyncEventHandler =
        (InboxSync.Event, InboxSync.State, InboxSync.Model) -> (InboxSync.State, InboxSync.Model)

    public enum State {
        case initial
        case imapLoggingIn
        case imapFetchingFolders
        case determiningFolderUIDs
        case imapFetchingNewMessages
        case imapSyncingExistingMessages
        case determiningIdleCapability
        case imapIdling
        case imapWaitingAndRepeat
        case imapSendingDrafts
        case smtpLoggingIn
        case smtpSending
        case smtpImapAppending
        case fatalImapError
        case fatalSmtpError
    }

    /**
     Possible events, or requests from outside.
     */
    public enum Event {
        case start
        case imapLoggedIn
        case imapFoldersFetched
        case folderUIDsDetermined
        case doesSupportIdle
        case doesNotSupportIdle
        case imapNewMessagesFetched
        case imapExistingMessagesSynced
        case imapExistingMessageSyncSkipped

        /**
         After polling delay has expired, or when requested, or when IDLE has
         indicated new messages.
         */
        case shouldReSync

        case fatalImapError
        case fatalSmtpError
        case imapError
        case coreDataError
        case requestSync
        case requestSmtp
        case requestDraft
    }

    public struct Model {
        /** The currently executed operation */
        var operation: BaseOperation? = nil

        /** In case of a fatal IMAP error, this is set */
        var fatalImapError: Error? = nil

        /** In case of an IMAP error, that might be remedied by repetion, this is set */
        var imapError: Error? = nil

        /** In case of a fatal SMTP error, this is set */
        var fatalSmtpError: Error? = nil

        /** Minor error, will retry again */
        var minorImapError: Error? = nil

        /** Minor error, will retry again */
        var minorSmtpError: Error? = nil

        /** Set if there is a request from the outside */
        var message: Event? = nil

        var supportsIdle = false

        var folderInfo: FolderUIDInfoProtocol = FolderUIDInfo()
    }

    typealias StateMachineType = AsyncStateMachine<State, Event, Model>

    var stateMachine: StateMachineType
    let parentName: String
    let imapSyncData: ImapSyncData
    let smtpSendData: SmtpSendData
    let pollDelayInSeconds: Double = 15

    var backgroundQueue = OperationQueue()
    let folderName: String = ImapSync.defaultImapInboxName

    public init(parentName: String? = nil, imapConnectInfo: EmailConnectInfo,
         smtpConnectInfo: EmailConnectInfo) {
        self.parentName = parentName ?? #function
        self.imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        self.smtpSendData = SmtpSendData(connectInfo: smtpConnectInfo)
        stateMachine = AsyncStateMachine(state: .initial, model: Model())
        setupTransitions()
        setupEnterStateHandlers()
    }

    public func start() {
        stateMachine.send(event: .start, onError: InboxSync.internalStateErrorHandler())
    }

    static func internalStateErrorHandler() -> StateMachineType.ErrorHandler {
        return { error in
            Log.shared.error(component: #function, error: error)
        }
    }

    func completionHandler(
        operation: BaseOperation, successEvent: Event, errorEvent: Event,
        successHandler: (() -> ())? = nil) -> (() -> ()) {
        return { [weak self] in
            self?.stateMachine.async {
                if let error = operation.error {
                    switch errorEvent {
                    case .fatalImapError:
                        self?.stateMachine.model.fatalImapError = error
                    case .fatalSmtpError:
                        self?.stateMachine.model.fatalSmtpError = error
                    case .imapError:
                        self?.stateMachine.model.imapError = error
                    default: ()
                    }
                    self?.stateMachine.send(event: errorEvent,
                                            onError: InboxSync.internalStateErrorHandler())
                } else {
                    if let block = successHandler {
                        block()
                    }
                    self?.stateMachine.send(
                        event: successEvent, onError: InboxSync.internalStateErrorHandler())
                }
            }
        }
    }

    func add(operation: BaseOperation, toModel: Model) -> Model {
        var model = toModel
        model.operation = operation
        return model
    }

    func install(
        operation: BaseOperation, model: Model, successEvent: Event, errorEvent: Event,
        successHandler: (() -> ())? = nil) -> Model {
        operation.completionBlock = completionHandler(
            operation: operation, successEvent: successEvent, errorEvent: errorEvent,
            successHandler: successHandler)
        backgroundQueue.addOperation(operation)
        return add(operation: operation, toModel: model)
    }

    func updateCapibilities(capabilities: Set<String>?) {
        if let caps = capabilities {
            self.stateMachine.model.supportsIdle = caps.contains("IDLE")
        }
    }

    func triggerImapLoginOperation(model: Model) -> Model {
        let op = LoginImapOperation(parentName: parentName, imapSyncData: imapSyncData)
        return install(
            operation: op,
            model: model, successEvent: .imapLoggedIn, errorEvent: .fatalImapError) { [weak self] in
                self?.stateMachine.async {
                    self?.updateCapibilities(capabilities: op.capabilities)
                }
        }
    }

    func triggerImapFolderFetchOperation(model: Model) -> Model {
        return install(
            operation: FetchFoldersOperation(parentName: parentName, imapSyncData: imapSyncData),
            model: model, successEvent: .imapFoldersFetched, errorEvent: .fatalImapError)
    }

    func triggerFolderInfoOperation(model: Model) -> Model {
        let op = FolderInfoOperation(
            parentName: parentName, connectInfo: imapSyncData.connectInfo,
            folderName: folderName)
        return install(
            operation: op,
            model: model, successEvent: .folderUIDsDetermined, errorEvent: .coreDataError) {
                [weak self] in
                self?.stateMachine.model.folderInfo = op.folderInfo
        }
    }

    func triggerFetchNewMessagesOperation(model: Model) -> Model {
        return install(
            operation: FetchMessagesOperation(
                parentName: parentName, imapSyncData: imapSyncData, folderName: folderName),
            model: model, successEvent: .imapNewMessagesFetched, errorEvent: .imapError)
    }

    func triggerSyncExistingMessagesOperation(model: Model) -> Model {
        return install(
            operation: SyncMessagesOperation(
                parentName: parentName, imapSyncData: imapSyncData, folderName: folderName,
                firstUID: model.folderInfo.firstUID, lastUID: model.folderInfo.lastUID),
            model: model, successEvent: .imapExistingMessagesSynced, errorEvent: .imapError)
    }

    func triggerWaitingOperation(model: Model) -> Model {
        return install(
            operation: DelayOperation(parentName: parentName, delayInSeconds: pollDelayInSeconds),
            model: model, successEvent: .shouldReSync, errorEvent: .imapError)
    }

    func setupTransitions() {
        stateMachine.addTransition(srcState: .initial, event: .start, targetState: .imapLoggingIn)
        stateMachine.addTransition(srcState: .imapLoggingIn, event: .imapLoggedIn,
                                   targetState: .imapFetchingFolders)
        stateMachine.addTransition(srcState: .imapFetchingFolders, event: .imapFoldersFetched,
                                   targetState: .determiningFolderUIDs)
        stateMachine.addTransition(srcState: .determiningFolderUIDs, event: .folderUIDsDetermined,
                                   targetState: .imapFetchingNewMessages)
        stateMachine.addTransition(srcState: .imapFetchingNewMessages,
                                   event: .imapNewMessagesFetched,
                                   targetState: .imapSyncingExistingMessages)
        stateMachine.addTransition(srcState: .imapSyncingExistingMessages,
                                   event: .imapExistingMessagesSynced,
                                   targetState: .imapFetchingNewMessages)
        stateMachine.addTransition(srcState: .imapFetchingNewMessages,
                                   event: .imapNewMessagesFetched,
                                   targetState: .imapSyncingExistingMessages)

        stateMachine.addTransition(srcState: .imapSyncingExistingMessages,
                                   event: .imapExistingMessageSyncSkipped,
                                   targetState: .determiningIdleCapability)
        stateMachine.addTransition(srcState: .imapSyncingExistingMessages,
                                   event: .imapExistingMessagesSynced,
                                   targetState: .determiningIdleCapability)

        stateMachine.addTransition(srcState: .determiningIdleCapability,
                                   event: .doesSupportIdle,
                                   targetState: .imapIdling)
        stateMachine.addTransition(srcState: .determiningIdleCapability,
                                   event: .doesNotSupportIdle,
                                   targetState: .imapWaitingAndRepeat)
        stateMachine.addTransition(srcState: .imapWaitingAndRepeat,
                                   event: .shouldReSync,
                                   targetState: .determiningFolderUIDs)
    }

    func setupEnterStateHandlers() {
        stateMachine.onEntering(state: .imapLoggingIn) { [weak self] state, model in
            return self?.triggerImapLoginOperation(model: model) ?? model
        }
        stateMachine.onEntering(state: .imapFetchingFolders) { [weak self] state, model in
            return self?.triggerImapFolderFetchOperation(model: model) ?? model
        }
        stateMachine.onEntering(state: .determiningFolderUIDs) { [weak self] state, model in
            return self?.triggerFolderInfoOperation(model: model) ?? model
        }
        stateMachine.onEntering(state: .imapFetchingNewMessages) { [weak self] state, model in
            return self?.triggerFetchNewMessagesOperation(model: model) ?? model
        }
        stateMachine.onEntering(state: .imapSyncingExistingMessages) { [weak self] state, model in
            let uidRangeLogInfo =
            "firstUID: \(model.folderInfo.firstUID), lastUID: \(model.folderInfo.lastUID)"
            if model.folderInfo.valid {
                if !model.folderInfo.empty {
                    return self?.triggerSyncExistingMessagesOperation(model: model) ?? model
                } else {
                    Log.shared.errorComponent(
                        #function,
                        message: "Sync message: Empty UID range: \(uidRangeLogInfo)")
                }
            } else {
                Log.shared.errorComponent(
                    #function,
                    message: "Sync message: Invalid UIDs: \(uidRangeLogInfo)")
            }
            self?.stateMachine.send(event: .imapExistingMessageSyncSkipped,
                                    onError: InboxSync.internalStateErrorHandler())
            return model
        }
        stateMachine.onEntering(state: .determiningIdleCapability) { [weak self] state, model in
            if model.supportsIdle {
                self?.stateMachine.send(event: .doesSupportIdle,
                                        onError: InboxSync.internalStateErrorHandler())
            } else {
                self?.stateMachine.send(event: .doesNotSupportIdle,
                                        onError: InboxSync.internalStateErrorHandler())
            }
            return model
        }
        stateMachine.onEntering(state: .imapWaitingAndRepeat) { [weak self] state, model in
            return self?.triggerWaitingOperation(model: model) ?? model
        }
    }
}
