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
        setupHandlers()
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

    func triggerImapLoginOperation(model: Model) -> Model {
        return install(
            operation: LoginImapOperation(parentName: parentName, imapSyncData: imapSyncData),
            model: model, successEvent: .imapLoggedIn, errorEvent: .fatalImapError)
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

    func setupHandlers() {
        stateMachine.handle(state: .initial, event: .start) {
            [weak self] theEvent, theState, theModel in
            return (.imapLoggingIn, self?.triggerImapLoginOperation(model: theModel) ?? theModel)
        }
        stateMachine.handle(state: .imapLoggingIn, event: .imapLoggedIn) {
            [weak self] theEvent, theState, theModel in
            return (.imapFetchingFolders,
                    self?.triggerImapFolderFetchOperation(model: theModel) ?? theModel)
        }
        stateMachine.handle(state: .imapFetchingFolders, event: .imapFoldersFetched) {
            [weak self] theEvent, theState, theModel in
            return (.determiningFolderUIDs,
                    self?.triggerFolderInfoOperation(model: theModel) ?? theModel)
        }
        stateMachine.handle(state: .determiningFolderUIDs, event: .folderUIDsDetermined) {
            [weak self] theEvent, theState, theModel in
            return (.imapFetchingNewMessages,
                    self?.triggerFetchNewMessagesOperation(model: theModel) ?? theModel)
        }
        stateMachine.handle(state: .imapFetchingNewMessages, event: .imapNewMessagesFetched) {
            [weak self] theEvent, theState, theModel in
            var newModel = theModel
            if theModel.folderInfo.firstUID != 0 && theModel.folderInfo.lastUID != 0 {
                newModel = self?.triggerSyncExistingMessagesOperation(model: theModel) ?? theModel
            } else {
                newModel.operation = nil
            }
            self?.stateMachine.send(event: .imapExistingMessageSyncSkipped,
                                    onError: InboxSync.internalStateErrorHandler())
            return (.imapSyncingExistingMessages, newModel)
        }

        let blockEnterIdlingOrWait: SyncEventHandler = {
            [weak self] theEvent, theState, theModel in
            if theModel.supportsIdle {
                // TODO: implement IDLE
                return (.imapIdling, theModel)
            } else {
                return (.imapWaitingAndRepeat,
                        self?.triggerWaitingOperation(model: theModel) ?? theModel)
            }
        }
        stateMachine.handle(
            state: .imapSyncingExistingMessages, event: .imapExistingMessagesSynced,
            handler: blockEnterIdlingOrWait)
        stateMachine.handle(
            state: .imapSyncingExistingMessages, event: .imapExistingMessageSyncSkipped,
            handler: blockEnterIdlingOrWait)

        let blockDoReSync: SyncEventHandler = {
            [weak self] theEvent, theState, theModel in
            return (.determiningFolderUIDs, theModel)
        }
    }
}
