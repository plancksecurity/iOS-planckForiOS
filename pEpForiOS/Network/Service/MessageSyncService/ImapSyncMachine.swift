//
//  ImapSyncMachine.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

extension ImapSyncMachine.State: Equatable {
    public static func ==(lhs: ImapSyncMachine.State, rhs: ImapSyncMachine.State) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.fetchFolders, .fetchFolders):
            return true
        case (.fetchNewMessages, .fetchNewMessages):
            return true
        case (.syncOldMessages, .syncOldMessages):
            return true
        case (.idle, .idle):
            return true
        case (.sendSMTP, .sendSMTP):
            return true
        case (.sendIMAP, .sendIMAP):
            return true
        case (.saveDrafts, .saveDrafts):
            return true
        case (.error, .error):
            return true
        case (.none, _), (.fetchFolders, _), (.fetchNewMessages, _),
             (.syncOldMessages, _), (.idle, _), (.sendSMTP, _), (.sendIMAP, _),
             (.saveDrafts, _), (.error, _):
            return false
        }
    }
}

public protocol ImapSyncMachineDelegate: class {
    func didFetchFolders(machine: ImapSyncMachine)
    func didFetchMessages(machine: ImapSyncMachine)
    func didSyncMessages(machine: ImapSyncMachine)
}

open class ImapSyncMachine {
    enum Input {
        case none
        case idle
        case smtpRequested
        case imapSyncRequested
        case saveDraftsRequested
    }
    
    enum State {
        case none
        case fetchFolders
        case fetchNewMessages
        case syncOldMessages
        case idle

        /** SMTP actions relating to sending mails */
        case sendSMTP

        /** IMAP actions relating to sending mails, like append to the sent folder */
        case sendIMAP

        case saveDrafts

        case error(Error)

        var isError: Bool {
            switch self {
            case .error:
                return true
            default:
                return false
            }
        }
    }

    public enum MachineError: Error {
        case invalidStateTransition
        case internalSyncMessagesProblem
        case noStateChange
    }

    private let imapSyncData: ImapSyncData
    private let smtpSendData: SmtpSendData

    private(set) var currentState = State.none
    private(set) var currentInput = Input.none

    private let managementQueue = DispatchQueue(
        label: "ImapSyncMachine.managementQueue", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    weak var delegate: ImapSyncMachineDelegate?

    init(imapConnectInfo: EmailConnectInfo, smtpConnectInfo: EmailConnectInfo) {
        self.imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        self.smtpSendData = SmtpSendData(connectInfo: smtpConnectInfo)
    }

    func set(input: Input) {
        managementQueue.async {
            self.setInternal(input: input)
        }
    }

    private func setInternal(input: Input) {
        if !(currentInput == .smtpRequested && input == .imapSyncRequested) {
            currentInput = input
        }
    }

    func start() {
        managementQueue.async { [weak self] in
            self?.transition(newState: .fetchFolders)
        }
    }

    private func transition(newState: State) {
        managementQueue.async { [weak self] in
            self?.entering(state: newState)
        }
    }

    private func entering(state: State) {
        managementQueue.async { [weak self] in
            guard let theSelf = self else {
                return
            }
            if theSelf.currentState.isError {
                return
            }
            if theSelf.currentState == state {
                theSelf.entering(state: .error(MachineError.invalidStateTransition))
            }

            if !state.isError {
                // handle delegate
                switch theSelf.currentState {
                case .fetchFolders:
                    theSelf.delegate?.didFetchFolders(machine: theSelf)
                case .fetchNewMessages:
                    theSelf.delegate?.didFetchMessages(machine: theSelf)
                case .syncOldMessages:
                    theSelf.delegate?.didSyncMessages(machine: theSelf)
                default:
                    break
                }
            }

            switch state {
            case .fetchFolders:
                theSelf.fetchFolders()
            case .fetchNewMessages:
                theSelf.fetchNewMessages()
            case .syncOldMessages:
                theSelf.syncMessages()
            case .idle:
                theSelf.keepOnIdlingOrNo()
                break
            case .sendSMTP:
                theSelf.sendSmtp()
            case .error:
                break
            default:
                theSelf.entering(state: .error(MachineError.invalidStateTransition))
            }
            theSelf.currentState = state
        }
    }

    private func keepOnIdlingOrNo() {
        switch currentInput {
        case .imapSyncRequested:
            transition(newState: .fetchNewMessages)
        case .smtpRequested:
            transition(newState: .sendSMTP)
        case .saveDraftsRequested:
            transition(newState: .saveDrafts)
        default:
            // keep on idling
            break
        }
    }

    private func sendSmtp() {
        let errorContainer = ErrorContainer()
        let loginSmtpOp = LoginSmtpOperation(
            parentName: #function, smtpSendData: smtpSendData, errorContainer: errorContainer)
        let sendOp = EncryptAndSendOperation(
            parentName: #function, smtpSendData: smtpSendData, errorContainer: errorContainer)
        sendOp.addDependency(loginSmtpOp)
        sendOp.completionBlock = { [weak self] in
            self?.handleError(errorContainer: errorContainer, newState: .sendIMAP)
        }
        backgroundQueue.addOperations([loginSmtpOp, sendOp], waitUntilFinished: false)
    }

    private func sendImap() {
        let errorContainer = ErrorContainer()
        let sendImapOp = AppendMailsOperation(
            parentName: #function, imapSyncData: imapSyncData, errorContainer: errorContainer)
        sendImapOp.completionBlock = { [weak self] in
            self?.handleError(errorContainer: errorContainer, newState: .fetchNewMessages)
        }
        backgroundQueue.addOperation(sendImapOp)
    }

    private func fetchFolders() {
        let errorContainer = ErrorContainer()
        let loginOp = LoginImapOperation(
            parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData)
        let fetchFoldersOp = FetchFoldersOperation(
            parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData,
            onlyUpdateIfNecessary: false, messageFetchedBlock: nil)
        fetchFoldersOp.addDependency(loginOp)
        fetchFoldersOp.completionBlock = { [weak self] in
            self?.handleError(errorContainer: errorContainer, newState: .fetchNewMessages)
        }
        backgroundQueue.addOperations([loginOp, fetchFoldersOp], waitUntilFinished: false)
    }

    private func fetchNewMessages() {
        let errorContainer = ErrorContainer()
        let fetchMessagesOp = FetchMessagesOperation(
            parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData,
            folderName: ImapSync.defaultImapInboxName, messageFetchedBlock: nil)
        fetchMessagesOp.completionBlock = { [weak self] in
            self?.handleError(errorContainer: errorContainer, newState: .syncOldMessages)
        }
        backgroundQueue.addOperation(fetchMessagesOp)
    }

    private func syncMessages() {
        let context = Record.Context.background
        context.perform {
            let errorContainer = ErrorContainer()
            guard
                let cdAccount = context.object(
                    with: self.imapSyncData.connectInfo.accountObjectID) as? CdAccount,
                let cdFolder = CdFolder.by(folderType: .inbox, account: cdAccount),
                let syncMessagesOp = SyncMessagesOperation(
                    parentName: #function, errorContainer: errorContainer,
                    imapSyncData: self.imapSyncData,
                    folder: cdFolder, firstUID: cdFolder.firstUID(), lastUID: cdFolder.lastUID())
                else {
                    self.transition(newState: .error(MachineError.internalSyncMessagesProblem))
                    return
            }
            syncMessagesOp.completionBlock = { [weak self] in
                self?.handleError(errorContainer: errorContainer, newState: .idle)
            }
            self.backgroundQueue.addOperation(syncMessagesOp)
        }
    }

    private func handleError(errorContainer: ErrorContainer, newState: State) {
        managementQueue.async {
            if let err = errorContainer.error {
                self.transition(newState: .error(err))
            } else {
                self.transition(newState: newState)
            }
        }
    }
}
