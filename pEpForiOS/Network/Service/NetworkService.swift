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

    /// Called after graceful shutdown.
    func networkServiceDidCancel(service:NetworkService)
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

    var serviceConfig: ServiceConfig
    public private(set) var currentWorker: NetworkServiceWorker?
    var newMailsService: FetchNumberOfNewMailsService?
    public weak var delegate: NetworkServiceDelegate?
    private var imapConnectionDataCache: ImapConnectionDataCache?
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
        currentWorker = NetworkServiceWorker(serviceConfig: serviceConfig,
                             imapConnectionDataCache: nil)
        currentWorker?.delegate = self
        currentWorker?.unitTestDelegate = self
    }

    /**
     Start endlessly synchronizing in the background.
     */
    public func start() {
        if currentWorker == nil {
            currentWorker = NetworkServiceWorker(serviceConfig: serviceConfig,
                                                 imapConnectionDataCache: imapConnectionDataCache)
        }
        currentWorker?.delegate = self
        currentWorker?.unitTestDelegate = self
        currentWorker?.start()
    }

    /// Stop endlessly synchronizing in the background, syncs all pending changes triggered by the
    /// user with server.
    /// Calls NetworkServiceDelegate networkServiceDidFinishLastSyncLoop() when done.
    public func processAllUserActionsAndstop() {
        saveCurrentWorkersConfigAndImapConnectionCache()
        currentWorker?.stop()
    }

    /**
     Cancel worker and services.
     */
    public func cancel() {
        saveCurrentWorkersConfigAndImapConnectionCache()
        currentWorker?.cancel()
        // Only to make sure. Should not be required.
        newMailsService?.stop()
    }

    public func checkForNewMails(completionHandler: @escaping (_ numNewMails: Int?) -> ()) {
        newMailsService = FetchNumberOfNewMailsService(imapConnectionDataCache: nil)
        newMailsService?.start(completionBlock: completionHandler)
    }

    // MARK: -

    private func saveCurrentWorkersConfigAndImapConnectionCache() {
        if let cache = currentWorker?.imapConnectionDataCache {
            imapConnectionDataCache = cache
        }
        if let config = currentWorker?.serviceConfig {
            serviceConfig = config
        }
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
}

// MARK: - NetworkServiceWorkerDelegate

extension NetworkService: NetworkServiceWorkerDelegate {
    public func networkServiceWorkerDidFinishLastSyncLoop(worker: NetworkServiceWorker) {
        GCD.onMain { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            me.delegate?.networkServiceDidFinishLastSyncLoop(service: me)
        }
    }

    public func networkServiceWorkerDidCancel(worker: NetworkServiceWorker) {
        GCD.onMain { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            me.delegate?.networkServiceDidCancel(service: me)
        }
    }

    public func networkServiceWorker(_ worker: NetworkServiceWorker, errorOccured error: Error) {
        GCD.onMain { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            me.serviceConfig.errorPropagator?.report(error: error)
        }
    }
}

 // MARK: - UNIT TEST ONLY

public protocol NetworkServiceUnitTestDelegate: class {
    /** Called after each account sync */
    func networkServiceDidSync(service: NetworkService, accountInfo: AccountConnectInfo,
                               errorProtocol: ServiceErrorProtocol)
}

// MARK: NetworkServiceWorkerUnitTestDelegate

extension NetworkService: NetworkServiceWorkerUnitTestDelegate {
    public func testWorkerDidSync(worker: NetworkServiceWorker,
                                            accountInfo: AccountConnectInfo,
                                            errorProtocol: ServiceErrorProtocol) {
        self.unitTestDelegate?.networkServiceDidSync(service: self,
                                                     accountInfo: accountInfo,
                                                     errorProtocol: errorProtocol)
    }
}
