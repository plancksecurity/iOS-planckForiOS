//
//  PEPUtilTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class PEPUtilTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPepContact() {
        var c1 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some.com", name: "Whatever")
        c1.userID = "someUserID"

        let pepC1 = PEPUtil.pepContact(c1)

        XCTAssertEqual(pepC1[kPepAddress] as? String, c1.email)
        XCTAssertEqual(pepC1[kPepUsername] as? String, c1.name)
        XCTAssertEqual(pepC1[kPepUserID] as? String, c1.userID)
    }

    func testPepAttachment() {
        let data = "Just some plaintext".dataUsingEncoding(NSUTF8StringEncoding)!
        var a1 = persistentSetup.model.insertAttachmentWithContentType(
            "text/plain", filename: "excel.txt",
            data: data)

        let pepA1 = PEPUtil.pepAttachment(a1)

        XCTAssertEqual(pepA1[kPepMimeFilename] as? String, a1.filename)
        XCTAssertEqual(pepA1[kPepMimeType] as? String, a1.contentType)
        XCTAssertEqual(pepA1[kPepMimeData] as? NSData, a1.content.data)
    }

    func testPepMail() {
        var c1 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some.com", name: "Whatever")
        c1.userID = "someUserID"

        var c2 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some2.com", name: "Whatever2")
        c2.userID = "someUserID"

        let data1 = "Just some plaintext".dataUsingEncoding(NSUTF8StringEncoding)!
        let a1 = persistentSetup.model.insertAttachmentWithContentType(
            "text/plain", filename: "excel.txt",
            data: data1)

        let data2 = "Just some plaintext2".dataUsingEncoding(NSUTF8StringEncoding)!
        let a2 = persistentSetup.model.insertAttachmentWithContentType(
            "text/plain", filename: "excel2.txt",
            data: data2)

        let message = persistentSetup.model.insertNewMessage() as! Message
        message.subject = "Some subject"
        message.longMessage = "Long message"
        message.longMessageFormatted = "Long HTML"

        message.addToObject(c1 as! Contact)
        message.addCcObject(c2 as! Contact)

        message.addAttachmentsObject(a1 as! Attachment)
        message.addAttachmentsObject(a2 as! Attachment)

        let pepMail = PEPUtil.pepMail(message)

        XCTAssertEqual(pepMail[kPepTo]?[0] as? NSMutableDictionary, PEPUtil.pepContact(c1))
        XCTAssertEqual(pepMail[kPepCC]?[0] as? NSMutableDictionary, PEPUtil.pepContact(c2))

        XCTAssertEqual(pepMail[kPepAttachments]?[0] as? NSMutableDictionary,
                       PEPUtil.pepAttachment(a1))
        XCTAssertEqual(pepMail[kPepAttachments]?[1] as? NSMutableDictionary,
                       PEPUtil.pepAttachment(a2))

        XCTAssertEqual(pepMail[kPepShortMessage] as? String, message.subject)
        XCTAssertEqual(pepMail[kPepLongMessage] as? String, message.longMessage)
        XCTAssertEqual(pepMail[kPepLongMessageFormatted] as? String, message.longMessageFormatted)
    }
}