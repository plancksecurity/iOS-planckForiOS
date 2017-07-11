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
    /**
     Will be invoked once messages have been sent.
     - parameter service: The service that has sent the messages
     - parameter messages: The requested messages that have been sent
     - parameter allMessageIDs: The message IDs of *all* the messages that have been sent,
     requested or not.
     */
    func messagesSent(service: ImapSmtpSyncService,
                      messages: [Message],
                      allMessageIDs: [MessageID])

    func handle(service: ImapSmtpSyncService, error: Error)
}

class ImapSmtpSyncService {
    weak var delegate: ImapSmtpSyncServiceDelegate?

    let parentName: String?
    let backgrounder: BackgroundTaskProtocol?

    let serviceFactory = ServiceFactory()
    var currentlyRunningService: ServiceExecutionProtocol?

    var lastSuccessfullySentMessageIDs = [MessageID]()

    enum State {
        case initial
        case initialSync

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
        case .idling, .waitingForNextSync, .error, .haveSent:
            return true
        case .initial, .initialSync, .sending:
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
            state = .initialSync
            sendRequested = false
            let service = serviceFactory.initialSync(
                parentName: parentName, backgrounder: backgrounder,
                imapSyncData: imapSyncData, smtpSendData: smtpSendData,
                smtpSendServiceDelegate: self)
            currentlyRunningService = service
            service.execute() { [weak self] error in
                self?.handleInitialSyncFinished(error: error)
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
            let sendService = SmtpSendService(
                parentName: parentName, backgrounder: backgrounder,
                imapSyncData: imapSyncData, smtpSendData: smtpSendData)
            currentlyRunningService = sendService
            sendService.execute() { [weak self] error in
                self?.handleSendRequestFinished(error: error)
            }
        } else {
            if state == .initial {
                start()
            } else {
                sendRequested = true
            }
        }
    }

    func handleError(error: Error?) {
        resetConnectionsOn(error: error)
        if let err = error {
            delegate?.handle(service: self, error: err)
        }
    }

    func handleInitialSyncFinished(error: Error?) {
        handleError(error: error)
        notifyAboutSentMessages()
        if error == nil {
            if imapSyncData.supportsIdle {
                state = .idling
            } else {
                state = .waitingForNextSync
            }
        }
        checkNextStep()
    }

    func handleSendRequestFinished(error: Error?) {
        handleError(error: error)
        notifyAboutSentMessages()
        state = .haveSent
        checkNextStep()
    }

    func notifyAboutSentMessages() {
        var messagesWithSuccess = [Message]()
        for mID in lastSuccessfullySentMessageIDs {
            if let msg = messagesEnqueuedForSend[mID] {
                messagesWithSuccess.append(msg)
                messagesEnqueuedForSend[mID] = nil
            }
        }

        if !messagesWithSuccess.isEmpty || !lastSuccessfullySentMessageIDs.isEmpty {
            delegate?.messagesSent(service: self, messages: messagesWithSuccess,
                                   allMessageIDs: lastSuccessfullySentMessageIDs)
        }
        lastSuccessfullySentMessageIDs.removeAll()
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

extension ImapSmtpSyncService: SmtpSendServiceDelegate {
    func sent(messageIDs: [MessageID]) {
        lastSuccessfullySentMessageIDs.append(contentsOf: messageIDs)
    }
}
