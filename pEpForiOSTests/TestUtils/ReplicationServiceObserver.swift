//
//  ReplicationServiceObserver.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 29.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class ReplicationServiceObserver: CustomDebugStringConvertible {
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
}

// MARK: - ReplicationServiceUnitTestDelegate

extension ReplicationServiceObserver: ReplicationServiceUnitTestDelegate {
    func replicationServiceDidSync(service: ReplicationService, accountInfo: AccountConnectInfo,
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
}

// MARK: - ReplicationServiceDelegate
extension ReplicationServiceObserver: ReplicationServiceDelegate {
    func replicationServiceDidFinishLastSyncLoop(service: ReplicationService) {
        // ignore
    }

    func replicationServiceDidCancel(service: ReplicationService) {
        expCanceled?.fulfill()
    }
}
