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
    let comp = "PepAdapterTests"
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
        NSLog("PGP fingerprint (me): " + String(describing: identity_me[kPepFingerprint]!))
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
            Log.info(component: comp, "key = \(key)")
        }
        
        XCTAssertNotNil(identity[kPepFingerprint], "A fingerprint, there is!")
        
        PEPiOSAdapter.stopKeyserverLookup()
    }
    
    func testPepPaths() {
        var error: NSError?
        
        // Test if paths exist.
        for key in PEPUtil.pEpUrls.keys {
            XCTAssertTrue((PEPUtil.pEpUrls[key]! as NSURL).checkResourceIsReachableAndReturnError(&error))
        }
        
        Log.info(component: comp, "Home folder: " + String(describing: PEPUtil.pEpUrls["home"]))
        Log.info(component: comp, "pEp management DB file: " + String(describing: PEPUtil.pEpUrls["pEpManagementDb"]))
        Log.info(component: comp, "GnuPG folder: " + String(describing: PEPUtil.pEpUrls["gnupg"]))
        Log.info(component: comp, "Secring file: " + String(describing: PEPUtil.pEpUrls["gnupgSecring"]))
        Log.info(component: comp, "Pubring file: " + String(describing: PEPUtil.pEpUrls["gnupgPubring"]))
        
        // Test if paths are not nil.
        for key in PEPUtil.pEpUrls.keys {
            XCTAssertNotNil(PEPUtil.pEpUrls[key])
        }

    }
    
    func testPepClean() {
        // XXX: To test later
        // XCTAssertTrue(PEPUtil.pEpClean())
    }
    
}
