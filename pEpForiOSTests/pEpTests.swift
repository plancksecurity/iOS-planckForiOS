//
//  pEpTests.swift
//  pEpForiOS
//
//  Created by hernani on 03/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

class pEpTests: XCTestCase {
    var pEpSession: PEPSession?
    
    override func setUp() {
        super.setUp()
        pEpSession = PEPSession()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPEpSession() {
        XCTAssertNotNil(pEpSession)
    }
    
    // XXX: Parts of this should be in PEPUtil module.
    func testKeyServerLookup() {
        PEPiOSAdapter.startKeyserverLookup()
        
        var identity = NSMutableDictionary()
        identity = ["username": "hernani",
                    "address": "hernani@pep.foundation",
                    "user_id": "2342"]
        NSLog("Dict size: %d", identity.count)
        
        pEpSession!.updateIdentity(identity)
        
        XCTAssertTrue(identity.count > 3,
                      "Identity dictionary was "
                        + "(successfully) modified by reference.")
        NSLog("Dict size: %d", identity.count)
        
        for key in identity.allKeys {
            NSLog("key = \(key)")
        }
        
        XCTAssertTrue(identity.objectForKey("fpr") != nil,
                      "A Fingerprint, there is!")
        NSLog("PGP-Fingerprint: " + String(identity["fpr"]!))
        
        PEPiOSAdapter.stopKeyserverLookup()
    }
    
}