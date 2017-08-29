//
//  NetworkServiceObserver.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 29.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import pEpForiOS
import MessageModel

class NetworkServiceObserver: NetworkServiceDelegate, CustomDebugStringConvertible {
    let expAllSynced: XCTestExpectation?
    var expCanceled: XCTestExpectation?
    var accountInfo: AccountConnectInfo?
    let numAccountsToBeSynced: Int
    var numAccountsSynced = 0

    var debugDescription: String {
        return expAllSynced?.debugDescription ?? "unknown"
    }

    let failOnError: Bool

    init(numAccountsToSync: Int = 1, expAccountsSynced: XCTestExpectation? = nil, expCanceled: XCTestExpectation? = nil,
         failOnError: Bool = false) {
        self.numAccountsToBeSynced = numAccountsToSync
        self.expAllSynced = expAccountsSynced
        self.expCanceled = expCanceled
        self.failOnError = failOnError
    }

    func didSync(service: NetworkService, accountInfo: AccountConnectInfo,
                 errorProtocol: ServiceErrorProtocol) {
        Log.info(component: #function, content: "\(self)")
        if errorProtocol.hasErrors() && failOnError {
            Log.error(component: #function, error: errorProtocol.error)
            XCTFail()
        }
        if self.accountInfo == nil {
            self.accountInfo = accountInfo
        }
        numAccountsSynced += 1
        if numAccountsToBeSynced == numAccountsSynced {
            expAllSynced?.fulfill()
        }
    }

    func didCancel(service: NetworkService) {
        expCanceled?.fulfill()
    }
}

class SendLayerObserver: SendLayerDelegate {
    let expAccountVerified: XCTestExpectation?
    var messageIDs = [String]()

    init(expAccountVerified: XCTestExpectation? = nil) {
        self.expAccountVerified = expAccountVerified
    }

    func didVerify(cdAccount: CdAccount, error: Error?) {
        XCTAssertNil(error)
        expAccountVerified?.fulfill()
    }

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
