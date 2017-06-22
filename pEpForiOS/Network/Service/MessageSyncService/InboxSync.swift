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
    public enum State {
        case initial
        case imapLogin
        case imapFetchFolders
        case imapFetchNewMessages
        case imapSyncExistingMessages
        case imapIdle
        case imapWaitAndRepeat
        case imapDraft
        case smtpLogin
        case smtpSend
        case smtpImapAppend
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
        case imapNewMessagesFetched
        case imapExistingMessagesSynced
        case fatalImapError
        case fatalSmtpError
        case imapError
        case requestSync
        case requestSmtp
        case requestDraft
    }

    public struct Model {
        /** The currently executed operation */
        var operation: BaseOperation? = nil

        /** In case of a fatal IMAP error, this is set */
        var fatalImapError: Error? = nil

        /** In case of a fatal SMTP error, this is set */
        var fatalSmtpError: Error? = nil

        /** Minor error, will retry again */
        var minorImapError: Error? = nil

        /** Minor error, will retry again */
        var minorSmtpError: Error? = nil

        /** Set if there is a request from the outside */
        var message: Event? = nil

        var supportsIdle = false
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
        operation: BaseOperation, successEvent: Event, errorEvent: Event) -> (() -> ()) {
        return { [weak self] in
            self?.stateMachine.async {
                if let error = operation.error {
                    switch errorEvent {
                    case .fatalImapError:
                        self?.stateMachine.model.fatalImapError = error
                        self?.stateMachine.send(event: errorEvent,
                                   onError: InboxSync.internalStateErrorHandler())
                    case .fatalSmtpError:
                        self?.stateMachine.model.fatalSmtpError = error
                    default: ()
                    }
                } else {
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
        operation: BaseOperation, model: Model, successEvent: Event, errorEvent: Event) -> Model {
        operation.completionBlock = completionHandler(
            operation: operation, successEvent: successEvent, errorEvent: errorEvent)
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

    func triggerFetchNewMessagesOperation(model: Model) -> Model {
        return install(
            operation: FetchMessagesOperation(imapSyncData: imapSyncData, folderName: folderName),
            model: model, successEvent: .imapNewMessagesFetched, errorEvent: .imapError)
    }

    func triggerSyncExistingMessagesOperation(model: Model) -> Model {
        // success: .imapExistingMessagesSynced
        // error: .imapError
        var theModel = model
        theModel.operation = nil
        return theModel
    }

    func setupHandlers() {
        stateMachine.handle(state: .initial, event: .start) {
            [weak self] theEvent, theState, theModel in
            return (.imapLogin, self?.triggerImapLoginOperation(model: theModel) ?? theModel)
        }
        stateMachine.handle(state: .imapLogin, event: .imapLoggedIn) {
            [weak self] theEvent, theState, theModel in
            return (.imapFetchFolders,
                    self?.triggerImapFolderFetchOperation(model: theModel) ?? theModel)
        }
        stateMachine.handle(state: .imapFetchFolders, event: .imapFoldersFetched) {
            [weak self] theEvent, theState, theModel in
            return (.imapFetchNewMessages,
                    self?.triggerFetchNewMessagesOperation(model: theModel) ?? theModel)
        }
        stateMachine.handle(state: .imapFetchNewMessages, event: .imapNewMessagesFetched) {
            [weak self] theEvent, theState, theModel in
            return (.imapSyncExistingMessages,
                    self?.triggerSyncExistingMessagesOperation(model: theModel) ?? theModel)
        }
    }
}
