//
//  NetworkServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class NetworkServiceTests: XCTestCase {
    
    var persistenceSetup: PersistentSetup!
    
    let networkService = NetworkService()

    var cdAccount1: CdAccount!
    var cdAccount2: CdAccount!
    
    override func setUp() {
        super.setUp()
        
        // Initialize Core Data layer.
        persistenceSetup = PersistentSetup()
        cdAccount1 = TestData().createWorkingCdAccount()
        cdAccount2 = TestData().createWorkingCdAccount(number: 2)
        Record.saveAndWait()

        networkService.start()
    }
    
    override func tearDown() {
        persistenceSetup = nil
    }
}
