//
//  ImapSmtpSyncService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol ImapSmtpSyncServiceDelegate: class {
    func messagesSent(service: ImapSmtpSyncService, messages: [Message])
    func handle(service: ImapSmtpSyncService, error: Error)
}

class ImapSmtpSyncService {
    weak var delegate: ImapSmtpSyncServiceDelegate?

    let parentName: String?
    let backgrounder: BackgroundTaskProtocol?

    enum State {
        case initial

        case fetchingFolders
        case haveFetchedFolders
        case sending
        case haveSent

        /** Using the real IMAP IDLE command */
        case idling

        /** In case the server does not support IDLE */
        case waitingForNextSync

        case error
    }

    private var state: State = .initial
    private var imapSyncData: ImapSyncData
    private var smtpSendData: SmtpSendData
    private var sendRequested: Bool = false
    private var messagesEnqueuedForSend = [MessageID: Message]()

    var readyForSend: Bool {
        switch state {
        case .haveFetchedFolders, .idling, .waitingForNextSync, .error, .haveSent:
            return true
        case .fetchingFolders, .initial, .sending:
            return false
        }
    }

    init(parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
         imapSyncData: ImapSyncData, smtpSendData: SmtpSendData) {
        self.parentName = parentName
        self.backgrounder = backgrounder
        self.imapSyncData = imapSyncData
        self.smtpSendData = smtpSendData
    }

    public func start() {
        if state == .initial {
            state = .fetchingFolders
            let fetchFoldersService = FetchFoldersService(
                parentName: parentName, backgrounder: backgrounder)
            fetchFoldersService.execute(imapSyncData: imapSyncData) { [weak self] error in
                self?.handleFetchFoldersFinished(service: fetchFoldersService, error: error)
            }
        }
    }

    public func enqueueForSending(message: Message) {
        let key = message.messageID
        messagesEnqueuedForSend[key] = message
        sendMessages()
    }

    func sendMessages()  {
        if readyForSend {
            sendRequested = false
            state = .sending
            let sendService = SmtpSendService(parentName: parentName, backgrounder: backgrounder)
            sendService.execute(smtpSendData: smtpSendData, imapSyncData: imapSyncData)
            { [weak self] error in
                self?.handleSendRequestFinished(service: sendService, error: error)
            }
        } else {
            sendRequested = true
            if state == .initial {
                start()
            }
        }
    }

    func handleError(error: Error?) {
        resetConnectionsOn(error: error)
        if let err = error {
            delegate?.handle(service: self, error: err)
        }
    }

    func handleFetchFoldersFinished(service: FetchFoldersService, error: Error?) {
        handleError(error: error)
        if error == nil {
            state = .haveFetchedFolders
        }
        checkNextStep()
    }

    func handleSendRequestFinished(service: SmtpSendService, error: Error?) {
        handleError(error: error)

        var messagesWithSuccess = [Message]()
        for mID in service.successfullySentMessageIDs {
            if let msg = messagesEnqueuedForSend[mID] {
                messagesWithSuccess.append(msg)
                messagesEnqueuedForSend[mID] = nil
            }
        }

        if !messagesWithSuccess.isEmpty {
            delegate?.messagesSent(service: self, messages: messagesWithSuccess)
        }

        state = .haveSent
        checkNextStep()
    }

    func resetConnectionsOn(error: Error?) {
        if let _ = error {
            imapSyncData.reset()
            smtpSendData.reset()
        }
    }

    func checkNextStep() {
        if sendRequested && readyForSend {
            sendMessages()
        }
    }
}
