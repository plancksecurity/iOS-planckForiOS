//
//  NetworkService.swift
//  pEpForiOS
//
//  Created by hernani on 10/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

public protocol NetworkServiceDelegate: class {
    /// Called finishing the last sync loop.
    /// No further sync loop will be triggered after this call.
    /// All operations finished before this call.
    func networkServiceDidFinishLastSyncLoop(service:NetworkService)
}

/**
 * Provides all the IMAP and SMTP syncing. Will constantly run in the background.
 */
public class NetworkService {
    public class ServiceConfig {
        /**
         Folders (other than inbox) that the user looked at
         in the last `timeIntervalForInterestingFolders`
         are considered sync-worthy.
         */
        public var timeIntervalForInterestingFolders: TimeInterval = 60 * 60 * 24
        
        /**
         Amount of time to "sleep" between complete syncs of all accounts.
         */
        public var sleepTimeInSeconds: Double

        public var sendLayerDelegate: SendLayerDelegate?

        let parentName: String
        let mySelfer: KickOffMySelfProtocol?
        let backgrounder: BackgroundTaskProtocol?
        var errorPropagator: ErrorPropagator?

        init(sleepTimeInSeconds: Double,
             parentName: String,
             mySelfer: KickOffMySelfProtocol?,
             backgrounder: BackgroundTaskProtocol?,
             errorPropagator: ErrorPropagator?) {
            self.sleepTimeInSeconds = sleepTimeInSeconds
            self.parentName = parentName
            self.mySelfer = mySelfer
            self.backgrounder = backgrounder
            self.errorPropagator = errorPropagator
        }
    }

    public enum State {
        case running
        case stopped
    }

    public private(set) var state = State.stopped

    var serviceConfig: ServiceConfig
    public private(set) var currentWorker: NetworkServiceWorker?
    var newMailsService: FetchNumberOfNewMailsService?
    public weak var delegate: NetworkServiceDelegate?
    // UNIT TEST ONLY
    public weak var unitTestDelegate: NetworkServiceUnitTestDelegate?

    /**
     Amount of time to "sleep" between complete syncs of all accounts.
     */
    public var sleepTimeInSeconds: Double {
        get {
            return serviceConfig.sleepTimeInSeconds
        }
        set {
            serviceConfig.sleepTimeInSeconds = newValue
        }
    }

    /**
     The connection cache from the last service worker, in case we go to the background.
     */
    var lastConnectionDataCache: [EmailConnectInfo: ImapSyncData]?

    public var timeIntervalForInterestingFolders: TimeInterval {
        get {
            return serviceConfig.timeIntervalForInterestingFolders
        }
        set {
            serviceConfig.timeIntervalForInterestingFolders = newValue
        }
    }

    public init(sleepTimeInSeconds: Double = 5.0,
                parentName: String = #function,
                backgrounder: BackgroundTaskProtocol? = nil,
                mySelfer: KickOffMySelfProtocol? = nil,
                errorPropagator: ErrorPropagator? = nil) {
        serviceConfig = ServiceConfig(sleepTimeInSeconds: sleepTimeInSeconds,
                                      parentName: parentName,
                                      mySelfer: mySelfer ??
                                        DefaultMySelfer( parentName: parentName,
                                                         backgrounder: backgrounder),
                                      backgrounder: backgrounder,
                                      errorPropagator: errorPropagator)
    }

    /**
     Start endlessly synchronizing in the background.
     */
    public func start() {
        currentWorker = NetworkServiceWorker(serviceConfig: serviceConfig)
        currentWorker?.delegate = self
        currentWorker?.unitTestDelegate = self
        state = .running
        currentWorker?.start()
    }

    /// Stop endlessly synchronizing in the background, syncs all pending changes triggered by the
    /// user with server.
    /// Calls NetworkServiceDelegate networkServiceDidFinishLastSyncLoop() when done.
    public func processAllUserActionsAndstop() {
        currentWorker?.stop()
    }

    /**
     Cancel worker and services.
     */
    public func cancel() {
        // Keep the current config
        if let config = currentWorker?.serviceConfig {
            serviceConfig = config
        }
        //476.SOI
        lastConnectionDataCache = currentWorker?.imapConnectionDataCache
        currentWorker?.cancel()
        currentWorker = nil

        // Only to make sure. Should not be required.
        newMailsService?.stop()
    }

    public func checkForNewMails(completionHandler: @escaping (_ numNewMails: Int?) -> ()) {
        newMailsService = FetchNumberOfNewMailsService(imapConnectionDataCache: nil)
        newMailsService?.start(completionBlock: completionHandler)
    }

    public func internalVerify(cdAccount account: CdAccount) {
        cancel() // cancel the current worker
        currentWorker = NetworkServiceWorker(serviceConfig: serviceConfig)
        currentWorker?.start()
    }
}

// MARK: - SendLayerProtocol

extension NetworkService: SendLayerProtocol {
    public var sendLayerDelegate: SendLayerDelegate? {
        set {
            serviceConfig.sendLayerDelegate = newValue
        }
        get {
            return serviceConfig.sendLayerDelegate
        }
    }

    public func verify(cdAccount: CdAccount) {
        internalVerify(cdAccount: cdAccount)
    }
}

// MARK: - NetworkServiceWorkerDelegate

extension NetworkService: NetworkServiceWorkerDelegate {
    public func networkServicWorkerDidFinishLastSyncLoop(worker: NetworkServiceWorker) {
        state = .stopped
        self.delegate?.networkServiceDidFinishLastSyncLoop(service: self)
    }

    public func networkServiceWorker(_ worker: NetworkServiceWorker, errorOccured error: Error) {
        GCD.onMain {
            self.serviceConfig.errorPropagator?.report(error: error)
        }
    }
}

 // MARK: - UNIT TEST ONLY

public protocol NetworkServiceUnitTestDelegate: class {
    /** Called after each account sync */
    func networkServiceDidSync(service: NetworkService, accountInfo: AccountConnectInfo,
                               errorProtocol: ServiceErrorProtocol)

    /** Called after all operations have been canceled */
    func networkServiveDidCancel(service: NetworkService)
}

// MARK: NetworkServiceWorkerUnitTestDelegate

extension NetworkService: NetworkServiceWorkerUnitTestDelegate {
    public func networkServiceWorkerDidCancel(worker: NetworkServiceWorker) {
        self.unitTestDelegate?.networkServiveDidCancel(service: self)
    }
    
    public func networkServiceWorkerDidSync(worker: NetworkServiceWorker,
                                            accountInfo: AccountConnectInfo,
                                            errorProtocol: ServiceErrorProtocol) {
        self.unitTestDelegate?.networkServiceDidSync(service: self,
                                                     accountInfo: accountInfo,
                                                     errorProtocol: errorProtocol)
    }
}
