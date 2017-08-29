//
//  NetworkServiceObserver.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 29.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import pEpForiOS

class NetworkServiceObserver: NetworkServiceDelegate, CustomDebugStringConvertible {
    let expSingleAccountSynced: XCTestExpectation?
    var expCanceled: XCTestExpectation?
    var accountInfo: AccountConnectInfo?

    var debugDescription: String {
        return expSingleAccountSynced?.debugDescription ?? "unknown"
    }

    let failOnError: Bool

    init(expAccountsSynced: XCTestExpectation? = nil, expCanceled: XCTestExpectation? = nil,
         failOnError: Bool = false) {
        self.expSingleAccountSynced = expAccountsSynced
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
            expSingleAccountSynced?.fulfill()
        }
    }

    func didCancel(service: NetworkService) {
        expCanceled?.fulfill()
    }
}
