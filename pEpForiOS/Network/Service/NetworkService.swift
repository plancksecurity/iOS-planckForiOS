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
    /** Called after each account sync */
    func didSync(service: NetworkService, accountInfo: AccountConnectInfo,
                 errorProtocol: ServiceErrorProtocol)

    /** Called after all operations have been canceled */
    func didCancel(service: NetworkService)
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
        public weak var networkServiceDelegate: NetworkServiceDelegate?
        public var networkService: NetworkService?
        let parentName: String?
        let mySelfer: KickOffMySelfProtocol?
        let backgrounder: BackgroundTaskProtocol?

        init(
            networkService: NetworkService?, sleepTimeInSeconds: Double, parentName: String?,
            mySelfer: KickOffMySelfProtocol?, backgrounder: BackgroundTaskProtocol?) {
            self.networkService = networkService
            self.sleepTimeInSeconds = sleepTimeInSeconds
            self.parentName = parentName
            self.mySelfer = mySelfer
            self.backgrounder = backgrounder
        }
    }

    var serviceConfig: ServiceConfig
    public private(set) var currentWorker: NetworkServiceWorker?

    public weak var networkServiceDelegate: NetworkServiceDelegate? {
        get {
            return serviceConfig.networkServiceDelegate
        }
        set {
            serviceConfig.networkServiceDelegate = newValue
        }
    }

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

    public init(sleepTimeInSeconds: Double = 10.0,
                parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
                mySelfer: KickOffMySelfProtocol? = nil) {
        serviceConfig = ServiceConfig(
            networkService: nil, sleepTimeInSeconds: sleepTimeInSeconds,
            parentName: parentName,
            mySelfer: mySelfer ?? DefaultMySelfer(backgrounder: backgrounder),
            backgrounder: backgrounder)
        serviceConfig.networkService = self
    }

    /**
     Start endlessly synchronizing in the background.
     */
    public func start() {
        currentWorker = NetworkServiceWorker(serviceConfig: serviceConfig)
        currentWorker?.start()
    }

    /**
     Cancel the worker.
     */
    public func cancel() {
        // Keep the current config
        if let config = currentWorker?.serviceConfig {
            serviceConfig = config
        }
        lastConnectionDataCache = currentWorker?.imapConnectionDataCache
        currentWorker?.cancel(networkService: self)
        currentWorker = nil
    }

    public func quickSync(completionHandler: @escaping (QuickSyncResult) -> ()) {
        let connectionCache = currentWorker?.imapConnectionDataCache ?? lastConnectionDataCache
        cancel()
        let quickSync = QuickSyncService(imapConnectionDataCache: connectionCache)
        quickSync.sync(completionBlock: completionHandler)
    }

    public var timeIntervalForInterestingFolders: TimeInterval {
        get {
            return serviceConfig.timeIntervalForInterestingFolders
        }
        set {
            serviceConfig.timeIntervalForInterestingFolders = newValue
        }
    }

    public func internalVerify(cdAccount account: CdAccount) {
        cancel() // cancel the current worker
        currentWorker = NetworkServiceWorker(serviceConfig: serviceConfig)
        currentWorker?.start()
    }
}

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
