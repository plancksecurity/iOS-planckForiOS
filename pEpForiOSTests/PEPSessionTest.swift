//
//  PEPSessionTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class PEPSessionTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    /**
     Some code for accessing `NSBundle`s from Swift.
     */
    func showBundles() {
        for bundle in NSBundle.allBundles() {
            dumpBundle(bundle)
        }

        let testBundle = NSBundle.init(forClass: PEPSessionTest.self)
        dumpBundle(testBundle)
    }

    /**
     Print some essential properties of a bundle to the console.
     */
    func dumpBundle(bundle: NSBundle) {
        print("bundle \(bundle.bundleIdentifier) \(bundle.bundlePath)")
    }

    /**
     Import a key with the given file name from our own test bundle.
     - Parameter session: The pEp session to import the key into.
     - Parameter fileName: The file name of the key (complete with extension)
     */
    func importKeyByFileName(session: PEPSession, fileName: String) {
        let testBundle = NSBundle.init(forClass: PEPSessionTest.self)
        guard let keyPath = testBundle.pathForResource(fileName, ofType: nil) else {
            XCTAssertTrue(false, "Could not find key with file name \(fileName)")
            return
        }
        guard let data = NSData.init(contentsOfFile: keyPath) else {
            XCTAssertTrue(false, "Could not load key with file name \(fileName)")
            return
        }
        guard let content = NSString.init(data: data, encoding: NSASCIIStringEncoding) else {
            XCTAssertTrue(false, "Could not convert key with file name \(fileName) into data")
            return
        }
        session.importKey(content as String)
    }

    func setupSomeIdentities(session: PEPSession)
        -> (identity: NSMutableDictionary, receiver1: NSMutableDictionary,
        receiver2: NSMutableDictionary, receiver3: NSMutableDictionary,
        receiver4: NSMutableDictionary) {
            let identity: NSMutableDictionary = [:]
            identity[kPepUsername] = "myself"
            identity[kPepAddress] = "somewhere@overtherainbow.com"

            let receiver1: NSMutableDictionary = [:]
            receiver1[kPepUsername] = "receiver1"
            receiver1[kPepAddress] = "receiver1@shopsmart.com"

            let receiver2: NSMutableDictionary = [:]
            receiver2[kPepUsername] = "receiver2"
            receiver2[kPepAddress] = "receiver2@shopsmart.com"

            let receiver3: NSMutableDictionary = [:]
            receiver3[kPepUsername] = "receiver3"
            receiver3[kPepAddress] = "receiver3@shopsmart.com"

            let receiver4: NSMutableDictionary = [:]
            receiver4[kPepUsername] = "receiver4"
            receiver4[kPepAddress] = "receiver4@shopsmart.com"

            return (identity, receiver1, receiver2, receiver3, receiver4)
    }

    func testFilterOutUnencryptedReceiversForPEPMail() {
        let session = PEPSession.init()
        let (identity, receiver1, receiver2, receiver3, _) = setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        let pepMail: NSMutableDictionary = [:]
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = [identity, receiver1]
        pepMail[kPepCC] = [identity, receiver2]
        pepMail[kPepBCC] = [identity, receiver3]
        pepMail[kPepShortMessage] = "Subject"
        pepMail[kPepLongMessage] = "Some body text"

        let (unencryptedReceivers, encryptedBCC, pepMailPurged)
            = session.filterOutSpecialReceiversForPEPMail(pepMail as PEPSession.PEPMail)
        XCTAssertEqual(unencryptedReceivers,
                       [PEPSession.PEPRecipient.init(recipient: receiver1, recipientType: .To),
                        PEPSession.PEPRecipient.init(recipient: receiver2, recipientType: .CC),
                        PEPSession.PEPRecipient.init(recipient: receiver3, recipientType: .BCC)])
        XCTAssertEqual(encryptedBCC,
                       [PEPSession.PEPRecipient.init(recipient: identity, recipientType: .BCC)])
        XCTAssertEqual(pepMailPurged[kPepTo]
            as? NSArray, NSArray.init(array: [identity]))
        XCTAssertEqual(pepMailPurged[kPepCC] as? NSArray, NSArray.init(array: [identity]))
        XCTAssertEqual(pepMailPurged[kPepBCC] as? NSArray, NSArray.init(array: []))
    }

    func testPEPMailBuckets() {
        let session = PEPSession.init()
        let (identity, receiver1, receiver2, receiver3, _) = setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        let pepMail: NSMutableDictionary = [:]
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = [identity, receiver1]
        pepMail[kPepCC] = [identity, receiver2]
        pepMail[kPepBCC] = [identity, receiver3]
        pepMail[kPepShortMessage] = "Subject"
        pepMail[kPepLongMessage] = "Some body text"

        let (encrypted, unencrypted) = session.bucketsForPEPMail(pepMail as PEPSession.PEPMail)
        XCTAssertEqual(encrypted.count, 2)
        XCTAssertEqual(unencrypted.count, 1)

        XCTAssertEqual(encrypted[0][kPepTo] as? NSArray, [identity])
        XCTAssertEqual(encrypted[0][kPepCC] as? NSArray, [identity])
        XCTAssertEqual(encrypted[0][kPepBCC] as? NSArray, [])

        XCTAssertEqual(encrypted[1][kPepTo] as? NSArray, [])
        XCTAssertEqual(encrypted[1][kPepCC] as? NSArray, [])
        XCTAssertEqual(encrypted[1][kPepBCC] as? NSArray, [identity])

        XCTAssertEqual(unencrypted[0][kPepTo] as? NSArray, [receiver1])
        XCTAssertEqual(unencrypted[0][kPepCC] as? NSArray, [receiver2])
        XCTAssertEqual(unencrypted[0][kPepBCC] as? NSArray, [receiver3])
    }

    func testPEPMailBuckets2() {
        let session = PEPSession.init()

        importKeyByFileName(session,
                            fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

        let (identity, receiver1, receiver2, receiver3, receiver4) = setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        let pepMail: NSMutableDictionary = [:]
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = [identity, receiver1]
        pepMail[kPepCC] = [identity, receiver2]
        pepMail[kPepBCC] = [identity, receiver3, receiver4]
        pepMail[kPepShortMessage] = "Subject"
        pepMail[kPepLongMessage] = "Some body text"

        let (encrypted, unencrypted) = session.bucketsForPEPMail(pepMail as PEPSession.PEPMail)
        XCTAssertEqual(encrypted.count, 3)
        XCTAssertEqual(unencrypted.count, 1)

        XCTAssertEqual(encrypted[0][kPepTo] as? NSArray, [identity])
        XCTAssertEqual(encrypted[0][kPepCC] as? NSArray, [identity])
        XCTAssertEqual(encrypted[0][kPepBCC] as? NSArray, [])

        XCTAssertEqual(encrypted[1][kPepTo] as? NSArray, [])
        XCTAssertEqual(encrypted[1][kPepCC] as? NSArray, [])
        XCTAssertEqual(encrypted[1][kPepBCC] as? NSArray, [identity])

        XCTAssertEqual(encrypted[2][kPepTo] as? NSArray, [])
        XCTAssertEqual(encrypted[2][kPepCC] as? NSArray, [])
        XCTAssertEqual(encrypted[2][kPepBCC] as? NSArray, [receiver4])

        XCTAssertEqual(unencrypted[0][kPepTo] as? NSArray, [receiver1])
        XCTAssertEqual(unencrypted[0][kPepCC] as? NSArray, [receiver2])
        XCTAssertEqual(unencrypted[0][kPepBCC] as? NSArray, [receiver3])
    }
}