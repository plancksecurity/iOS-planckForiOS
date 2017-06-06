//
//  ImapSyncMachine.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

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

        case error(Error)
    }

    public enum MachineError: Error {
        case invalidStateTransition
        case internalSyncMessagesProblem
    }

    private let imapSyncData: ImapSyncData

    private(set) var currentState = State.none
    private(set) var currentInput = Input.none

    private let managementQueue = DispatchQueue(
        label: "ImapSyncMachine.managementQueue", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    weak var delegate: ImapSyncMachineDelegate?

    init(emailConnectInfo: EmailConnectInfo) {
        self.imapSyncData = ImapSyncData(connectInfo: emailConnectInfo)
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
            switch state {
            case .fetchFolders:
                theSelf.fetchFolders()
            case .fetchNewMessages:
                theSelf.delegate?.didFetchFolders(machine: theSelf)
                theSelf.fetchNewMessages()
            case .syncOldMessages:
                theSelf.syncMessages()
                theSelf.delegate?.didFetchMessages(machine: theSelf)
            case .idle:
                theSelf.delegate?.didSyncMessages(machine: theSelf)
            case .error:
                break
            default:
                theSelf.entering(state: .error(MachineError.invalidStateTransition))
            }
            theSelf.currentState = state
        }
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
