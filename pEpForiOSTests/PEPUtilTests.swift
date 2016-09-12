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
    /**
     Those keys in contacts should not interfere with equality tests.
     */
    let keysNotToCompare = [kPepUsername, kPepIsMe, kPepInReplyTo, kPepReferences]

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

        let c2 = AddressbookContact.init(email: "some@email.com")
        let pepC2 = PEPUtil.pepContact(c2)
        XCTAssertEqual(pepC2[kPepAddress] as? String, c2.email)
        XCTAssertEqual(pepC2[kPepUsername] as? String, "some")
        XCTAssertNil(pepC2[kPepUserID])

        let c3 = AddressbookContact.init(email: "some_iaeuiae@email.com")
        let pepC3 = PEPUtil.pepContact(c3)
        XCTAssertEqual(pepC3[kPepAddress] as? String, c3.email)
        XCTAssertEqual(pepC3[kPepUsername] as? String, "some_iaeuiae")
        XCTAssertNil(pepC3[kPepUserID])
}

    func testPepAttachment() {
        let data = "Just some plaintext".dataUsingEncoding(NSUTF8StringEncoding)!
        let a1 = persistentSetup.model.insertAttachmentWithContentType(
            "text/plain", filename: "excel.txt",
            data: data)

        let pepA1 = PEPUtil.pepAttachment(a1)

        XCTAssertEqual(pepA1[kPepMimeFilename] as? String, a1.filename)
        XCTAssertEqual(pepA1[kPepMimeType] as? String, a1.contentType)
        XCTAssertEqual(pepA1[kPepMimeData] as? NSData, a1.data)
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

        XCTAssertEqual(pepMail[kPepTo]?[0] as? NSDictionary,
                       PEPUtil.pepContact(c1))
        XCTAssertEqual(pepMail[kPepCC]?[0] as? NSDictionary,
                       PEPUtil.pepContact(c2))

        XCTAssertEqual(pepMail[kPepAttachments]?[0] as? NSDictionary,
                       PEPUtil.pepAttachment(a1))
        XCTAssertEqual(pepMail[kPepAttachments]?[1] as? NSDictionary,
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
        pepMailOrig[kPepTo] = [PEPUtil.pepContactFromEmail(receiverToEmail,
            name: "receiverTo")] as [AnyObject]
        pepMailOrig[kPepCC] = [PEPUtil.pepContactFromEmail(receiverCCEmail,
                               name: "receiverCC")] as [AnyObject]
        pepMailOrig[kPepBCC] = [PEPUtil.pepContactFromEmail(receiverBCCEmail,
                                name: "receiverBCC")] as [AnyObject]
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
        let messageID2 = "messageID2"
        let message2Subject = "hah!"
        let inReplyTo = "inReplyTo"
        let messageIDs = ["messageID1", messageID2, "messageID3"]

        var referenced = messageIDs
        referenced.append(inReplyTo)

        let folder = persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: nil,
            accountEmail: persistentSetup.accountEmail)

        let msg = persistentSetup.model.insertNewMessage()
        msg.folder = folder as! Folder
        msg.messageID = messageID2
        msg.subject = message2Subject

        // Create pEp mail dict
        let pepMailOrig = NSMutableDictionary()
        pepMailOrig[kPepFrom] = PEPUtil.pepContactFromEmail("unittest.ios.4@peptest.ch",
                                                            name: "Unit 4")
        pepMailOrig[kPepTo] = [PEPUtil.pepContactFromEmail("unittest.ios.2@peptest.ch",
            name: "unit 2")]
        pepMailOrig[kPepCC] = [PEPUtil.pepContactFromEmail("unittest.ios.3@peptest.ch",
            name: "unit 3")]
            as [AnyObject]
        pepMailOrig[kPepBCC] = [PEPUtil.pepContactFromEmail("unittest.ios.4@peptest.ch",
            name: "unit 4")]
            as [AnyObject]
        pepMailOrig[kPepShortMessage] = "Subject"
        pepMailOrig[kPepLongMessage] = "Some Text"
        pepMailOrig[kPepLongMessageFormatted] = "<b>Some HTML</b>"
        pepMailOrig[kPepID] = "<message001@peptest.ch>"
        pepMailOrig[kPepOutgoing] = true
        pepMailOrig[kPepInReplyTo] = [inReplyTo]
        pepMailOrig[kPepReferences] = messageIDs

        // Convert to pantomime
        let pantMail = PEPUtil.pantomimeMailFromPep(pepMailOrig as PEPMail)
        pantMail.setFolder(CWIMAPFolder.init(name: ImapSync.defaultImapInboxName))

        XCTAssertNotNil(pantMail.from())
        XCTAssertEqual(pantMail.allReferences() as! [String], referenced)

        // Convert to model
        let message = persistentSetup.model.insertOrUpdatePantomimeMail(
            pantMail, accountEmail: persistentSetup.connectionInfo.email,
            forceParseAttachments: true)

        // Check model
        XCTAssertNotNil(message)
        XCTAssertNotNil(message?.from)
        XCTAssertNotNil(message?.messageID)
        XCTAssertEqual(message?.longMessage, pepMailOrig[kPepLongMessage] as? String)
        XCTAssertEqual(message?.longMessageFormatted, pepMailOrig[kPepLongMessageFormatted]
            as? String)
        XCTAssertEqual(message?.references.count, referenced.count)
        if let m = message {
            var counter = 0
            for ref in m.references {
                XCTAssertEqual(ref.messageID, referenced[counter])
                if counter == 1 {
                    XCTAssertNotNil(ref as? MessageReference)
                    if let r = ref as? MessageReference {
                        XCTAssertNotNil(r.message)
                    }
                }
                counter = counter + 1
            }
        }

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
            XCTAssertNil(pepMail[kPepInReplyTo])
            XCTAssertEqual(pepMail[kPepReferences] as! [String], referenced)
            let attachments = pepMail[kPepAttachments] as? NSArray
            XCTAssertTrue(attachments == nil || attachments?.count == 0)
            pepMail[kPepAttachments] = nil
            let pepMail2 = TestUtil.removeUnneededKeysForComparison(
                keysNotToCompare, fromMail: pepMail)
            let pepMailOrig2 = TestUtil.removeUnneededKeysForComparison(
                keysNotToCompare, fromMail: pepMailOrig)
            TestUtil.diffDictionaries(pepMail2, dict2: pepMailOrig2)
            XCTAssertEqual(pepMail2, pepMailOrig2)
        }
    }

    /**
     Same code as `testPepToPantomimeToPepWithoutAttachments`, but with some attachments.
     */
    func testPepToPantomimeToPepWithAttachments() {
        persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: nil,
            accountEmail: persistentSetup.accountEmail)

        // Some mail constants for later comparison
        let subject = "Subject"
        let longMessage = "Some text"
        let longMessageFormatted = "<b>Some HTML</b>"

        // Create pEp mail dict
        let pepMailOrig = NSMutableDictionary()
        pepMailOrig[kPepFrom] = PEPUtil.pepContactFromEmail("unittest.ios.4@peptest.ch",
                                                            name: "unit 4")
        pepMailOrig[kPepTo] = [PEPUtil.pepContactFromEmail("unittest.ios.1@peptest.ch",
            name: "unit 1")]
        pepMailOrig[kPepCC] = [PEPUtil.pepContactFromEmail("unittest.ios.2@peptest.ch",
            name: "unit 2")]
        pepMailOrig[kPepBCC] = [PEPUtil.pepContactFromEmail("unittest.ios.3@peptest.ch",
            name: "unit 3")]
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
            pantMail, accountEmail: persistentSetup.connectionInfo.email,
            forceParseAttachments: true)

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
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
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

    func testTrustwords() {
        XCTAssertEqual("0".compare("000"), NSComparisonResult.OrderedAscending)
        XCTAssertEqual("111".compare("000"), NSComparisonResult.OrderedDescending)

        let fpr1 = "DB4713183660A12ABAFA7714EBE90D44146F62F4"
        let fpr2 = "4ABE3AAF59AC32CFE4F86500A9411D176FF00E97"

        let session = PEPSession.init()

        XCTAssertEqual(
            PEPUtil.shortTrustwordsForFpr(fpr1, language: "en", session: session),
            "BAPTISMAL BERTRAND DIVERSITY SCOTSWOMAN TRANSDUCER")
        XCTAssertEqual(
            PEPUtil.shortTrustwordsForFpr(fpr2, language: "en", session: session),
            "FROZE EDGEWISE HOTHEADED DERREK BRITNI")
        XCTAssertEqual(fpr1.compare(fpr2), NSComparisonResult.OrderedDescending)

        let dict1 = [kPepFingerprint: fpr1, kPepUserID: "1", kPepAddress: "email1",
                     kPepUsername: "1"]
        let dict2 = [kPepFingerprint: fpr2, kPepUserID: "2", kPepAddress: "email2",
                     kPepUsername: "2"]
        let words = PEPUtil.trustwordsForIdentity1(dict1, identity2: dict2,
                                                   language: "en", session: session)
        XCTAssertEqual(words,
                       "FROZE EDGEWISE HOTHEADED DERREK BRITNI BAPTISMAL BERTRAND DIVERSITY SCOTSWOMAN TRANSDUCER")
    }

    func testEncryptedReceivers() {
        let session = PEPSession.init()

        let (origIdentity, _, _, _, receiver4) =
            TestUtil.setupSomeIdentities(session)
        let identity = origIdentity.mutableCopy() as! NSMutableDictionary
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        // Import public key for receiver4
        TestUtil.importKeyByFileName(
            session, fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

        // This might fail the first time the test is run
        // (see ENGINE-41)
        XCTAssertTrue(session.isEncryptedPEPContact(
            identity as PEPContact, from: identity as PEPContact))

        XCTAssertTrue(session.isEncryptedPEPContact(
            receiver4 as PEPContact, from: identity as PEPContact))
    }

    /**
     This needs access to the addressbook, otherwise it will just fail.
     */
    func testInsertPepContact() {
        var addressBookContact: IContact?
        let ab = AddressBook.init()
        let context = persistentSetup.coreDataUtil.privateContext()

        let testBlock = {
            let contacts = ab.allContacts()
            XCTAssertGreaterThan(contacts.count, 0)
            if let first = contacts.first {
                addressBookContact = first
            }

            let expAddressBookTransfered = self.expectationWithDescription(
                "expAddressBookTransfered")

            MiscUtil.transferAddressBook(context, blockFinished: { contacts in
                XCTAssertGreaterThan(contacts.count, 0)
                expAddressBookTransfered.fulfill()
            })

            self.waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
            })
        }

        TestUtil.runAddressBookTest(testBlock, addressBook: ab, testCase: self,
                                    waitTime: TestUtil.waitTime)
        XCTAssertNotNil(addressBookContact)

        if let abContact = addressBookContact {
            let pepContact = NSMutableDictionary()
            pepContact[kPepAddress] = abContact.email
            let contact = PEPUtil.insertPepContact(pepContact as PEPContact,
                                                   intoModel: persistentSetup.model)
            XCTAssertNotNil(contact.pepUserID)
            XCTAssertNotNil(contact.addressBookID)

            if let abID = contact.addressBookID {
                XCTAssertEqual(contact.pepUserID, String(abID))
            }
        }
    }

    func testFingerprintForContact() {
        let session = PEPSession.init()

        let (_, _, _, _, receiver4) =
            TestUtil.setupSomeIdentities(session)

        // Import public key for receiver4
        TestUtil.importKeyByFileName(
            session, fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

        let contact = PEPUtil.insertPepContact(receiver4, intoModel: persistentSetup.model)

        XCTAssertNotNil(PEPUtil.fingprprintForContact(contact, session: session))
        XCTAssertNotNil(PEPUtil.fingprprintForPepContact(receiver4, session: session))
    }

    /**
     Just test that there is no crash calling trust functions.
     */
    func testTrustPersonalKey() {
        let session = PEPSession.init()

        let (_, _, _, _, receiver4) =
            TestUtil.setupSomeIdentities(session)

        // Import public key for receiver4
        TestUtil.importKeyByFileName(
            session, fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

        let contact = PEPUtil.insertPepContact(receiver4, intoModel: persistentSetup.model)

        PEPUtil.trustContact(contact)
        PEPUtil.resetTrustForContact(contact)
        PEPUtil.mistrustContact(contact)
        PEPUtil.resetTrustForContact(contact)
    }
}