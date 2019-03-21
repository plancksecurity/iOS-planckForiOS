//
//  NetworkServiceObserver.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 29.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class NetworkServiceObserver: NetworkServiceUnitTestDelegate, NetworkServiceDelegate, CustomDebugStringConvertible {
    let expAllSynced: XCTestExpectation?
    var expCanceled: XCTestExpectation?
    var accountInfo: AccountConnectInfo?
    let numAccountsToBeSynced: Int
    var accountIDsSynced = Set<NSManagedObjectID>()

    var debugDescription: String {
        return expAllSynced?.debugDescription ?? "unknown"
    }

    let failOnError: Bool

    init(numAccountsToSync: Int = 1,
         expAccountsSynced: XCTestExpectation? = nil,
         expCanceled: XCTestExpectation? = nil,
         failOnError: Bool = false) {
        self.numAccountsToBeSynced = numAccountsToSync
        self.expAllSynced = expAccountsSynced
        self.expCanceled = expCanceled
        self.failOnError = failOnError
    }

    // MARK: - NetworkServiceUnitTestDelegate

    func networkServiceDidSync(service: NetworkService, accountInfo: AccountConnectInfo,
                 errorProtocol: ServiceErrorProtocol) {
        if errorProtocol.hasErrors() && failOnError {
            XCTFail()
        }
        if self.accountInfo == nil {
            self.accountInfo = accountInfo
        }
        accountIDsSynced.insert(accountInfo.accountID)
        if accountIDsSynced.count == numAccountsToBeSynced {
            expAllSynced?.fulfill()
        }
    }

    // MARK: - NetworkServiceDelegate
    
    func networkServiceDidFinishLastSyncLoop(service: NetworkService) {
        // ignore
    }

    func networkServiceDidCancel(service: NetworkService) {
        expCanceled?.fulfill()
    }
}

class SendLayerObserver: SendLayerDelegate {
    var messageIDs = [String]()

    func didFetch(cdMessage: CdMessage) {
        if let msg = cdMessage.message() {
            messageIDs.append(msg.messageID)
        } else {
            XCTFail()
        }
    }

    func didRemove(cdFolder: CdFolder) {
        XCTFail()
    }

    func didRemove(cdMessage: CdMessage) {
        XCTFail()
    }
}
