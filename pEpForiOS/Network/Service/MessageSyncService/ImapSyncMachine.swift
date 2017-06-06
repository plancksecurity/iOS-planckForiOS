//
//  ImapSyncMachine.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

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
    }

    private let imapSyncData: ImapSyncData

    private(set) var currentState = State.none
    private(set) var currentInput = Input.none

    private let managementQueue = DispatchQueue(
        label: "ImapSyncMachine.managementQueue", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

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
            switch state {
            case .fetchFolders:
                self?.fetchFolders()
            case .fetchNewMessages:
                self?.fetchNewMessages()
            case .error:
                break
            default:
                self?.entering(state: .error(MachineError.invalidStateTransition))
            }
            self?.currentState = state
        }
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

    private func handleError(errorContainer: ErrorContainer, newState: State) {
        managementQueue.async {
            if let err = errorContainer.error {
                self.transition(newState: .error(err))
            } else {
                self.transition(newState: newState)
            }
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
}
