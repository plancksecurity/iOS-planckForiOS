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
    enum Action {
        case imapLogin
        case imapFetchFolders
        case imapSyncNewMessages
        case imapSyncOldMessages
        case imapIdle
        case imapWaitAndRepeat
        case imapDraft
        case smtpLogin
        case smtpSend
        case smtpImapAppend
        case fatalError
    }

    public enum RequestError: Error {
        /** Cannot execute the given request */
        case invalidRequest
    }

    /**
     Possible messages (requests) from outside
     */
    public enum Message {
        case requestSync
        case requestSmtp
        case requestDraft
    }

    struct State {
        /** The currently executed operation */
        var operation: BaseOperation?

        /** In case of a fatal error, this is set */
        var fatalError: Error?

        /** Minor error, will retry again */
        var error: Error?

        /** Set if there is a request from the outside */
        var message: Message?

        var currentAction: Action

        var supportsIdle = false

        static func empty() -> State {
            return State(
                operation: nil, fatalError: nil, error: nil, message: nil,
                currentAction: .imapLogin, supportsIdle: false)
        }
    }

    private let managementQueue = DispatchQueue(
        label: "InboxSync.managementQueue", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    var state: State = State.empty()

    let parentName: String
    let imapSyncData: ImapSyncData
    let smtpSendData: SmtpSendData
    let pollDelayInSeconds: Double = 15

    init(parentName: String? = nil, imapConnectInfo: EmailConnectInfo,
         smtpConnectInfo: EmailConnectInfo) {
        self.parentName = parentName ?? #function
        self.imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        self.smtpSendData = SmtpSendData(connectInfo: smtpConnectInfo)
    }

    public func request(message: Message) throws {
        if state.fatalError == nil {
            throw RequestError.invalidRequest
        }
        if let lastRequest = state.message {
            if lastRequest == .requestSmtp && message == .requestSync {
                // A full SMTP implies sync already
                return
            }
            if lastRequest == .requestSync && message == .requestSmtp {
                // This combination is ok
            }
        }
        state.message = message
    }

    func nextAction(oldOperation: BaseOperation) -> Action {
        if let err = oldOperation.error {
            state.error = err
            switch state.currentAction {
            case .imapLogin, .smtpLogin:
                state.fatalError = err
                return .fatalError
            case .imapFetchFolders, .imapSyncNewMessages, .imapSyncOldMessages, .imapIdle,
                 .imapDraft, .imapWaitAndRepeat:
                return .imapLogin
            case .smtpImapAppend:
                // try again
                return .smtpImapAppend
            case .smtpSend:
                // try again
                return .smtpSend
            case .fatalError:
                return .fatalError
            }
        }
        switch state.currentAction {
        case .imapLogin:
            return .imapFetchFolders
        case .imapFetchFolders:
            return .imapSyncNewMessages
        case .imapSyncNewMessages:
            return .imapSyncOldMessages
        case .imapSyncOldMessages:
            if state.supportsIdle {
                return .imapIdle
            }
            return .imapWaitAndRepeat
        case .imapWaitAndRepeat:
            return nextActionFromInput() ?? .imapSyncNewMessages
        case .imapIdle:
            return nextActionFromInput() ?? .imapIdle
        case .imapDraft:
            return .imapSyncNewMessages
        case .smtpLogin:
            return .smtpSend
        case .smtpSend:
            return .smtpImapAppend
        case .smtpImapAppend:
            return .imapSyncNewMessages
        case .fatalError:
            return .fatalError
        }
    }

    func nextActionFromInput() -> Action? {
        if let request = state.message {
            switch request {
            case .requestDraft:
                return .imapDraft
            case .requestSmtp:
                return .smtpLogin
            case .requestSync:
                return .imapSyncNewMessages
            }
        }
        return nil
    }

    func operationFromCurrentAction(block: @escaping (BaseOperation) -> ()) {
        switch state.currentAction {
        case .imapLogin:
            block(LoginImapOperation(parentName: parentName, imapSyncData: imapSyncData))
        case .imapFetchFolders:
            block(FetchFoldersOperation(
                parentName: parentName, imapSyncData: imapSyncData))
        case .imapSyncNewMessages:
            block(FetchMessagesOperation(
                parentName: parentName, imapSyncData: imapSyncData,
                folderName: ImapSync.defaultImapInboxName))
        case .imapSyncOldMessages:
            let context = Record.Context.background
            context.perform {
                guard
                    let cdAccount = context.object(
                        with: self.imapSyncData.connectInfo.accountObjectID) as? CdAccount,
                    let cdFolder = CdFolder.by(folderType: .inbox, account: cdAccount),
                    let folderName = cdFolder.name else {
                        return
                }
                let op = SyncMessagesOperation(
                    imapSyncData: self.imapSyncData, folderID: cdFolder.objectID,
                    folderName: folderName, firstUID: cdFolder.firstUID(),
                    lastUID: cdFolder.lastUID())
                block(op)
            }
        case .imapIdle:
            // TODO idle
            break
        case .imapWaitAndRepeat:
            block(DelayOperation(delayMilliseconds: pollDelayInSeconds))
            break
        case .imapDraft:
            block(
                AppendDraftMailsOperation(parentName: parentName, imapSyncData: self.imapSyncData))
        case .smtpLogin:
            block(LoginSmtpOperation(parentName: parentName, smtpSendData: self.smtpSendData))
        case .smtpSend:
            block(EncryptAndSendOperation(parentName: parentName, smtpSendData: self.smtpSendData))
        case .smtpImapAppend:
            block(AppendMailsOperation(parentName: parentName, imapSyncData: self.imapSyncData))
        case .fatalError:
            break
        }
    }

    func start() {
        self.managementQueue.async { [weak self] in
            self?.executeCurrentAction()
        }
    }

    func executeCurrentAction() {
        if let err = self.state.fatalError {
            Log.shared.error(component: #function, error: err)
            return
        }
        operationFromCurrentAction() { [weak self] op in
            self?.managementQueue.async {
                op.completionBlock = {
                    self?.managementQueue.async {
                        if let action = self?.nextAction(oldOperation: op) {
                            self?.state.currentAction = action
                            self?.executeCurrentAction()
                        }
                    }
                }
                self?.backgroundQueue.addOperation(op)
            }
        }
    }
}
