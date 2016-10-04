//
//  PepAdapterTests.swift
//  pEpForiOS
//
//  Created by hernani on 03/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class PepAdapterTests: XCTestCase {
    let identity_me: NSMutableDictionary = [kPepAddress: "some@mail.com",
                                            kPepUsername: "This is me"]
    var pEpSession: PEPSession!
    
    override func setUp() {
        super.setUp()
        pEpSession = PEPSession()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPepSession() {
        XCTAssertNotNil(pEpSession)
    }
    
    func testMyself() {
        // This includes that a new key is generated.
        pEpSession.mySelf(identity_me)
        NSLog("PGP fingerprint (me): " + String(identity_me[kPepFingerprint]!))
        XCTAssertNotNil(identity_me[kPepUserID])
    }
    
    // XXX: Parts of this should be in PEPUtil module.
    func testKeyServerLookup() {
        let identity: NSMutableDictionary = [kPepUsername: "hernani",
                                             kPepAddress: "hernani@pep.foundation",
                                             kPepUserID: "2342"]
        PEPiOSAdapter.startKeyserverLookup()
        sleep(4)
        
        pEpSession.updateIdentity(identity)
        
        XCTAssertTrue(identity.count > 3,
                      "Identity dictionary was "
                        + "(successfully) modified by reference.")

        for key in identity.allKeys {
            NSLog("key = \(key)")
        }
        
        XCTAssertNotNil(identity[kPepFingerprint], "A fingerprint, there is!")
        
        PEPiOSAdapter.stopKeyserverLookup()
    }
    
    func testPepPaths() {
        var error: NSError?
        
        NSLog("Home folder: " + String(PEPUtil.pEpUrls["home"]))
        NSLog("pEp management DB file: " + String(PEPUtil.pEpUrls["pEpManagementDb"]))
        NSLog("GnuPG folder: " + String(PEPUtil.pEpUrls["gnupg"]))
        NSLog("Secring file: " + String(PEPUtil.pEpUrls["gnupgSecring"]))
        NSLog("Pubring file: " + String(PEPUtil.pEpUrls["gnupgPubring"]))
        
        // Test if paths are not nil.
        for key in PEPUtil.pEpUrls.keys {
            XCTAssertNotNil(PEPUtil.pEpUrls[key])
        }
        // Test if paths exist.
        for key in PEPUtil.pEpUrls.keys {
            XCTAssertTrue((PEPUtil.pEpUrls[key]! as NSURL).checkResourceIsReachableAndReturnError(&error))
        }
    }
    
    func testPepClean() {
        // XXX: To test later
        // XCTAssertTrue(PEPUtil.pEpClean())
    }
    
}
