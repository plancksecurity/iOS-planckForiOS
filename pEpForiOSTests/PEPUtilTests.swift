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
    let waitTime: NSTimeInterval = 10

    /**
     Those keys in contacts should not interfere with equality tests.
     */
    let keysNotToCompare = ["username", "me"]

    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPepContact() {
        let c1 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some.com", name: "Whatever")
        c1.addressBookID = 1

        let pepC1 = PEPUtil.pepContact(c1)

        XCTAssertEqual(pepC1[kPepAddress] as? String, c1.email)
        XCTAssertEqual(pepC1[kPepUsername] as? String, c1.name)
        XCTAssertNotNil(pepC1[kPepUserID])
        XCTAssertEqual(pepC1[kPepUserID] as? String, String(c1.addressBookID!))
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
        let c1 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some.com", name: "Whatever")
        c1.addressBookID = 1

        let c2 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some2.com", name: "Whatever2")
        c2.addressBookID = 2

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

        let pepMail = PEPUtil.pepMail(message, outgoing: true)
        XCTAssertEqual(pepMail[kPepOutgoing] as? Bool, true)

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

    func testPantomimeMailFromPep() {
        let receiverToEmail = "unittest.ios.1@peptest.ch"
        let receiverCCEmail = "unittest.ios.2@peptest.ch"
        let receiverBCCEmail = "unittest.ios.3@peptest.ch"

        let pepMailOrig = NSMutableDictionary()
        pepMailOrig[kPepFrom] = PEPUtil.pepContactFromEmail("unittest.ios.4@peptest.ch",
                                                            name: "Unit 004")
        pepMailOrig[kPepTo] = [PEPUtil.pepContactFromEmail(receiverToEmail)] as [AnyObject]
        pepMailOrig[kPepCC] = [PEPUtil.pepContactFromEmail(receiverCCEmail)] as [AnyObject]
        pepMailOrig[kPepBCC] = [PEPUtil.pepContactFromEmail(receiverBCCEmail)] as [AnyObject]
        pepMailOrig[kPepShortMessage] = "Subject"
        pepMailOrig[kPepLongMessage] = "Some Text"
        pepMailOrig[kPepLongMessageFormatted] = "<b>Some HTML</b>"
        pepMailOrig[kPepID] = "<message001@peptest.ch>"
        pepMailOrig[kPepOutgoing] = true

        let pantMail = PEPUtil.pantomimeMailFromPep(pepMailOrig as PEPMail)

        XCTAssertEqual(pepMailOrig[kPepID] as? String, pantMail.messageID())
        XCTAssertEqual((pepMailOrig[kPepTo] as! [PEPContact])[0][kPepAddress] as? String,
                       receiverToEmail)

        XCTAssertEqual(pantMail.recipients().count, 3)

        let to = pantMail.recipients()[0] as? CWInternetAddress
        XCTAssertNotNil(to)
        XCTAssertEqual(to!.address(), receiverToEmail)

        let cc = pantMail.recipients()[1] as? CWInternetAddress
        XCTAssertNotNil(cc)
        XCTAssertEqual(cc!.address(), receiverCCEmail)

        let bcc = pantMail.recipients()[2] as? CWInternetAddress
        XCTAssertNotNil(bcc)
        XCTAssertEqual(bcc!.address(), receiverBCCEmail)

        let from = pantMail.from()
        XCTAssertNotNil(from)
        XCTAssertEqual(from!.address(), pepMailOrig[kPepFrom]![kPepAddress])

        XCTAssertEqual(pantMail.subject(), pepMailOrig[kPepShortMessage] as? String)

        XCTAssertEqual(pantMail.contentType(), Constants.contentTypeMultipartAlternative)
        let content = pantMail.content() as? CWMIMEMultipart
        XCTAssertNotNil(content)
        XCTAssertEqual(content?.count(), 2)

        let partText = content?.partAtIndex(0)
        XCTAssertNotNil(partText)
        let contentTextData = partText?.content() as? NSData
        XCTAssertNotNil(contentTextData)
        let contentText = String.init(data: contentTextData!, encoding: NSUTF8StringEncoding)
        XCTAssertEqual(contentText, pepMailOrig[kPepLongMessage] as? String)

        let partHtml = content?.partAtIndex(1)
        XCTAssertNotNil(partHtml)
        let contentHtmlData = partHtml?.content() as? NSData
        XCTAssertNotNil(contentHtmlData)
        let contentHtml = String.init(data: contentHtmlData!, encoding: NSUTF8StringEncoding)
        XCTAssertEqual(contentHtml, pepMailOrig[kPepLongMessageFormatted] as? String)
    }

    func testPepToPantomimeToPepWithoutAttachments() {
        persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, accountEmail: persistentSetup.accountEmail)

        // Create pEp mail dict
        let pepMailOrig = NSMutableDictionary()
        pepMailOrig[kPepFrom] = PEPUtil.pepContactFromEmail("unittest.ios.4@peptest.ch",
                                                            name: "Unit 4")
        pepMailOrig[kPepTo] = [PEPUtil.pepContactFromEmail("unittest.ios.2@peptest.ch")]
            as [AnyObject]
        pepMailOrig[kPepCC] = [PEPUtil.pepContactFromEmail("unittest.ios.3@peptest.ch")]
            as [AnyObject]
        pepMailOrig[kPepBCC] = [PEPUtil.pepContactFromEmail("unittest.ios.4@peptest.ch")]
            as [AnyObject]
        pepMailOrig[kPepShortMessage] = "Subject"
        pepMailOrig[kPepLongMessage] = "Some Text"
        pepMailOrig[kPepLongMessageFormatted] = "<b>Some HTML</b>"
        pepMailOrig[kPepID] = "<message001@peptest.ch>"
        pepMailOrig[kPepOutgoing] = true

        // Convert to pantomime
        let pantMail = PEPUtil.pantomimeMailFromPep(pepMailOrig as PEPMail)
        pantMail.setFolder(CWIMAPFolder.init(name: ImapSync.defaultImapInboxName))

        XCTAssertNotNil(pantMail.from())

        // Convert to model
        let message = persistentSetup.model.insertOrUpdatePantomimeMail(
            pantMail, accountEmail: persistentSetup.connectionInfo.email)

        // Check model
        XCTAssertNotNil(message)
        XCTAssertNotNil(message?.from)
        XCTAssertNotNil(message?.messageID)

        XCTAssertEqual(message?.to.count, 1)
        let tosOpt = message?.to
        XCTAssertNotNil(tosOpt)

        XCTAssertEqual(message?.cc.count, 1)
        let ccsOpt = message?.cc
        XCTAssertNotNil(ccsOpt)

        XCTAssertEqual(message?.bcc.count, 1)
        let bccsOpt = message?.bcc
        XCTAssertNotNil(bccsOpt)

        // Convert back to pEp
        if let m = message {
            var pepMail = PEPUtil.pepMail(m)
            let attachments = pepMail[kPepAttachments] as? NSArray
            XCTAssertTrue(attachments == nil || attachments?.count == 0)
            pepMail[kPepAttachments] = nil
            let pepMail2 = TestUtil.removeUnneededKeysForComparison(
                keysNotToCompare, fromMail: pepMail)
            let pepMailOrig2 = TestUtil.removeUnneededKeysForComparison(
                keysNotToCompare, fromMail: pepMailOrig)
            XCTAssertEqual(pepMail2, pepMailOrig2)
        }
    }

    /**
     Same code as `testPepToPantomimeToPepWithoutAttachments`, but with some attachments.
     */
    func testPepToPantomimeToPepWithAttachments() {
        persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, accountEmail: persistentSetup.accountEmail)

        // Some mail constants for later comparison
        let subject = "Subject"
        let longMessage = "Some text"
        let longMessageFormatted = "<b>Some HTML</b>"

        // Create pEp mail dict
        let pepMailOrig = NSMutableDictionary()
        pepMailOrig[kPepFrom] = PEPUtil.pepContactFromEmail("unittest.ios.4@peptest.ch",
                                                            name: "Test 001")
        pepMailOrig[kPepTo] = [PEPUtil.pepContactFromEmail("unittest.ios.1@peptest.ch")]
            as [AnyObject]
        pepMailOrig[kPepCC] = [PEPUtil.pepContactFromEmail("unittest.ios.2@peptest.ch")]
            as [AnyObject]
        pepMailOrig[kPepBCC] = [PEPUtil.pepContactFromEmail("unittest.ios.3@peptest.ch")]
            as [AnyObject]
        pepMailOrig[kPepShortMessage] = subject
        pepMailOrig[kPepLongMessage] = longMessage
        pepMailOrig[kPepLongMessageFormatted] = longMessageFormatted
        pepMailOrig[kPepID] = "<message001@peptest.ch>"
        pepMailOrig[kPepOutgoing] = true

        // Add Attachments

        var attachments: [NSMutableDictionary] = []

        let attachmentFilename1 = "some1.html"
        let attachment1 = NSMutableDictionary()
        attachment1[kPepMimeFilename] = attachmentFilename1
        attachment1[kPepMimeType] = Constants.contentTypeHtml
        attachment1[kPepMimeData] = (pepMailOrig[kPepLongMessageFormatted] as! String)
            .dataUsingEncoding(NSUTF8StringEncoding)
        attachments.append(attachment1)

        let attachmentFilename2 = "some2.html"
        let attachment2 = NSMutableDictionary()
        attachment2[kPepMimeFilename] = attachmentFilename2
        attachment2[kPepMimeType] = Constants.contentTypeHtml
        attachment2[kPepMimeData] = "<h1>Title only!</h1>".dataUsingEncoding(NSUTF8StringEncoding)
        attachments.append(attachment2)

        pepMailOrig[kPepAttachments] = attachments

        // Convert to pantomime
        let pantMail = PEPUtil.pantomimeMailFromPep(pepMailOrig as PEPMail)
        pantMail.setFolder(CWIMAPFolder.init(name: ImapSync.defaultImapInboxName))

        // Check pantomime

        XCTAssertNotNil(pantMail.from())
        XCTAssertEqual(pantMail.contentType(), Constants.contentTypeMultipartMixed)

        let partMain = pantMail.content() as? CWMIMEMultipart
        XCTAssertNotNil(partMain)
        XCTAssertEqual(partMain?.count(), 3)

        let partAlt = partMain?.partAtIndex(0)
        XCTAssertEqual(partAlt?.contentType(), Constants.contentTypeMultipartAlternative)

        let partAttachment1 = partMain?.partAtIndex(1)
        XCTAssertEqual(partAttachment1?.contentType(), Constants.contentTypeHtml)
        XCTAssertEqual(partAttachment1?.filename(), attachmentFilename1)
        XCTAssertNotNil(partAttachment1?.content())

        let partAttachment2 = partMain?.partAtIndex(2)
        XCTAssertEqual(partAttachment2?.contentType(), Constants.contentTypeHtml)
        XCTAssertEqual(partAttachment2?.filename(), attachmentFilename2)
        XCTAssertNotNil(partAttachment2?.content())

        // Convert to model
        let message = persistentSetup.model.insertOrUpdatePantomimeMail(
            pantMail, accountEmail: persistentSetup.connectionInfo.email)

        // Check model
        XCTAssertNotNil(message)
        XCTAssertNotNil(message?.from)
        XCTAssertNotNil(message?.messageID)

        XCTAssertEqual(message?.subject, subject)
        XCTAssertEqual(message?.longMessage, longMessage)
        XCTAssertEqual(message?.longMessageFormatted, longMessageFormatted)

        XCTAssertEqual(message?.to.count, 1)
        let tosOpt = message?.to
        XCTAssertNotNil(tosOpt)

        XCTAssertEqual(message?.cc.count, 1)
        let ccsOpt = message?.cc
        XCTAssertNotNil(ccsOpt)

        XCTAssertEqual(message?.bcc.count, 1)
        let bccsOpt = message?.bcc
        XCTAssertNotNil(bccsOpt)

        XCTAssertEqual(message?.attachments.count, 2)

        let modelAttachment1 = message?.attachments.objectAtIndex(0)
        XCTAssertNotNil(modelAttachment1)
        XCTAssertEqual(modelAttachment1?.filename, attachmentFilename1)
        XCTAssertEqual(modelAttachment1?.contentType, Constants.contentTypeHtml)

        let modelAttachment2 = message?.attachments.objectAtIndex(1)
        XCTAssertNotNil(modelAttachment2)
        XCTAssertEqual(modelAttachment2?.filename, attachmentFilename2)
        XCTAssertEqual(modelAttachment2?.contentType, Constants.contentTypeHtml)

        XCTAssertEqual(modelAttachment1!.filename, attachmentFilename1)
        XCTAssertEqual(modelAttachment2!.filename, attachmentFilename2)

        XCTAssertNotNil(message)

        // Convert back to pEp
        if let m = message {
            var pepMail = PEPUtil.pepMail(m)
            let attachments = pepMail[kPepAttachments] as? NSArray
            XCTAssertEqual(attachments?.count, 2)
            let pepMail2 = TestUtil.removeUnneededKeysForComparison(
                keysNotToCompare, fromMail: pepMail)
            let pepMailOrig2 = TestUtil.removeUnneededKeysForComparison(
                keysNotToCompare, fromMail: pepMailOrig)
            XCTAssertEqual(pepMail2, pepMailOrig2)
        }
    }

    func testColorRatingForContact() {
        let unknownContact = AddressbookContact.init(email: "unknownuser@peptest.ch")
        XCTAssertEqual(PEPUtil.colorRatingForContact(unknownContact), PEP_rating_undefined)

        // Create myself
        let expMyselfFinished = expectationWithDescription("expMyselfFinished")
        let account = persistentSetup.model.accountByEmail(persistentSetup.accountEmail)
        var identityMyself: NSDictionary? = nil
        PEPUtil.myselfFromAccount(account as! Account, block: { identity in
            expMyselfFinished.fulfill()
            identityMyself = identity
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNotNil(identityMyself)
            XCTAssertNotNil(identityMyself?[kPepFingerprint])
        })

        // Check rating for myself, should be at least yellow
        let contact = PEPUtil.insertPepContact(
            identityMyself?.mutableCopy() as! PEPContact, intoModel: persistentSetup.model)
        let rating = PEPUtil.colorRatingForContact(contact)
        XCTAssertGreaterThanOrEqual(rating.rawValue, PEP_rating_reliable.rawValue)
    }
}