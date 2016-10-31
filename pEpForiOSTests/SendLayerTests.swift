//
//  SendLayerTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class SendLayerTests: XCTestCase {
    let coreDataUtil = CoreDataUtil()
    let connectionManager = ConnectionManager()

    override func setUp() {
        super.setUp()
        let _ = PersistentSetup.init()
    }

    func testVerifySMTP() {
        let grandOp = GrandOperator(connectionManager: connectionManager,
                                    coreDataUtil: coreDataUtil)
    }
}
