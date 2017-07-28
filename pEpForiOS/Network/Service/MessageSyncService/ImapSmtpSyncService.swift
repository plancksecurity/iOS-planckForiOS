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

    func didSync(service: ImapSmtpSyncService)

    func startIdling(service: ImapSmtpSyncService)
}

class ImapSmtpSyncService {
    weak var delegate: ImapSmtpSyncServiceDelegate?

    let parentName: String?
    let backgrounder: BackgroundTaskProtocol?

    let serviceFactory = ServiceFactory()
    var currentlyRunningService: ServiceExecutionProtocol? {
        didSet {
            print("\(#function) \(String(describing: currentlyRunningService))")
        }
    }

    var lastSuccessfullySentMessageIDs = [MessageID]()

    enum State {
        case initial
        case initialSync

        case sending

        case readyForIdling

        /** Using the real IMAP IDLE command */
        case idling

        /** In case the server does not support IDLE */
        case waitingForNextSync

        case reSyncing

        case error
    }

    private(set) var imapSyncData: ImapSyncData
    private(set) var smtpSendData: SmtpSendData

    private var state: State = .initial
    private var sendRequested: Bool = false
    private var reSyncNecessary: Bool = false
    private var messagesEnqueuedForSend = [MessageID: Message]()
    private var messagesEnqueuedForFlagChange = Set<Message>()
    private var currentFolderName: String = ImapSync.defaultImapInboxName

    var readyForSend: Bool {
        switch state {
        case .idling, .waitingForNextSync, .error, .readyForIdling:
            return true
        case .initial, .initialSync, .sending, .reSyncing:
            return false
        }
    }

    var isIdling: Bool {
        switch state {
        case .idling, .waitingForNextSync:
            return true
        case .initial, .initialSync, .sending, .error, .readyForIdling, .reSyncing:
            return false
        }
    }

    init(parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
         imapSyncData: ImapSyncData, smtpSendData: SmtpSendData) {
        self.parentName = parentName
        self.backgrounder = backgrounder
        self.imapSyncData = imapSyncData
        self.smtpSendData = smtpSendData
        ReferenceCounter.inc(obj: self)
    }

    deinit {
        ReferenceCounter.dec(obj: self)
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
                self?.currentlyRunningService = nil
            }
        }
    }

    public func enqueueForSending(message: Message) {
        let key = message.messageID
        messagesEnqueuedForSend[key] = message
        sendMessages()
    }

    public func enqueueForFlagChange(message: Message) {
        messagesEnqueuedForFlagChange.insert(message)
        if isIdling {
            cancelIdling()
            let folderName = message.parent?.name ?? ImapSync.defaultImapInboxName
            var service: ServiceExecutionProtocol = serviceFactory.syncFlagsToServer(
                parentName: parentName, backgrounder: backgrounder,
                imapSyncData: imapSyncData, folderName: folderName)

            service = decoratedWithIdleExit(service: service)

            currentlyRunningService = service
            service.execute() { [weak self] error in
                self?.handleFlagUploadFinished(error: error)
                self?.currentlyRunningService = nil
            }
        }
    }

    public func cancel() {
        currentlyRunningService?.cancel()
        imapSyncData.sync?.close()
        smtpSendData.smtp?.close()
    }

    func decoratedWithIdleExit(service: ServiceExecutionProtocol) -> ServiceExecutionProtocol {
        if state == .idling {
            let exitIdleService = ImapIdleExitService(
                parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData)
            return ServiceChainExecutor(services: [exitIdleService, service])
        } else {
            return service
        }
    }

    func sendMessages()  {
        if readyForSend {
            cancelIdling()
            sendRequested = false
            state = .sending
            let sendService = SmtpSendService(
                parentName: parentName, backgrounder: backgrounder,
                imapSyncData: imapSyncData, smtpSendData: smtpSendData)
            currentlyRunningService = sendService
            sendService.execute() { [weak self] error in
                self?.handleSendRequestFinished(error: error)
                self?.currentlyRunningService = nil
            }
        } else {
            if state == .initial {
                start()
            } else {
                sendRequested = true
            }
        }
    }

    func jumpIntoCorrectIdleState() {
        if state != .error {
            state = .readyForIdling
        }
    }

    func handleError(error: Error?) {
        resetConnectionsOn(error: error)
        if let err = error {
            delegate?.handle(service: self, error: err)
            state = .error
        }
    }

    func handleInitialSyncFinished(error: Error?) {
        handleError(error: error)
        notifyAboutSentMessages()
        if error == nil {
            delegate?.didSync(service: self)
            jumpIntoCorrectIdleState()
        }
        checkNextStep()
    }

    func handleReSyncFinished(error: Error?) {
        handleError(error: error)
        if error == nil {
            delegate?.didSync(service: self)
            jumpIntoCorrectIdleState()
        }
        checkNextStep()
    }

    func handleSendRequestFinished(error: Error?) {
        handleError(error: error)
        notifyAboutSentMessages()
        jumpIntoCorrectIdleState()
        checkNextStep()
    }

    func handleFlagUploadFinished(error: Error?) {
        handleError(error: error)
        if error == nil {
            jumpIntoCorrectIdleState()
        }
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

    func reSync() {
        cancelIdling()
        var service = serviceFactory.reSync(
            parentName: parentName, backgrounder: backgrounder,
            imapSyncData: imapSyncData, folderName: currentFolderName)
        service = decoratedWithIdleExit(service: service)
        currentlyRunningService = service
        service.execute() { [weak self] error in
            self?.handleReSyncFinished(error: error)
            self?.currentlyRunningService = nil
        }
    }

    func cancelIdling() {
        if isIdling {
            currentlyRunningService?.cancel()
            currentlyRunningService = nil
        }
    }

    func checkNextStep() {
        if reSyncNecessary && isIdling {
            reSync()
            return
        }
        if sendRequested && readyForSend {
            sendMessages()
            return
        }
        if state == .readyForIdling {
            if imapSyncData.supportsIdle {
                state = .idling
                let imapIdleService = ImapIdleService(
                    parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData)
                currentlyRunningService = imapIdleService
                imapIdleService.execute() { [weak self] error in
                    self?.handleError(error: error)
                    if error == nil {
                        switch imapIdleService.idleResult {
                        case .newMessages:
                            self?.reSyncNecessary = true
                            self?.checkNextStep()
                            break
                        case .error:
                            break
                        case .nothing:
                            break
                        }
                    }
                    self?.currentlyRunningService = nil
                }
            } else {
                state = .waitingForNextSync
            }
            delegate?.startIdling(service: self)
            return
        }
    }
}

extension ImapSmtpSyncService: SmtpSendServiceDelegate {
    func sent(messageIDs: [MessageID]) {
        lastSuccessfullySentMessageIDs.append(contentsOf: messageIDs)
    }
}
