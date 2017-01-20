//
//  PEPSessionTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class PEPSessionTest: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

    }
    override func tearDown() {
        persistentSetup = nil

    }

    func testFilterOutUnencryptedReceiversForPEPMessage() {
        let session = PEPSession.init()
        let (identity, receiver1, receiver2, receiver3, _) = TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        var pepMail = PEPMessage()
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = NSArray.init(array: [identity, receiver1])
        pepMail[kPepCC] = NSArray.init(array: [identity, receiver2])
        pepMail[kPepBCC] = NSArray.init(array: [identity, receiver3])
        pepMail[kPepShortMessage] = "Subject" as AnyObject
        pepMail[kPepLongMessage] = "Some body text" as AnyObject

        let (unencryptedReceivers, encryptedBCC, pepMailPurged)
            = session.filterOutSpecialReceiversForPEPMessage(pepMail as PEPMessage)
        XCTAssertEqual(unencryptedReceivers,
                       [PEPRecipient.init(recipient: receiver1, recipientType: .to),
                        PEPRecipient.init(recipient: receiver2, recipientType: .cc),
                        PEPRecipient.init(recipient: receiver3, recipientType: .bcc)])
        XCTAssertEqual(encryptedBCC,
                       [PEPRecipient.init(recipient: identity as NSDictionary as! PEPIdentity,
                                          recipientType: .bcc)])
        XCTAssertEqual(pepMailPurged[kPepTo]
            as? NSArray, NSArray.init(array: [identity]))
        XCTAssertEqual(pepMailPurged[kPepCC] as? NSArray, NSArray.init(array: [identity]))
        XCTAssertEqual(pepMailPurged[kPepBCC] as? NSArray, NSArray.init(array: []))
    }

    func testPEPConversion() {
        let account = TestData().createWorkingAccount()
        account.save()

        let folder = Folder.create(name: "inbox", account: account, folderType: .inbox)
        folder.save()

        let uuid = UUID.generate()
        let message = Message.create(uuid: uuid)
        message.comments = "comment"
        message.shortMessage = "short message"
        message.longMessage = "long message"
        message.longMessageFormatted = "long message"
        message.from = account.user
        message.to = [account.user]
        message.cc = [account.user]
        message.bcc = [account.user]
        message.parent = folder
        message.sent = NSDate()
        message.replyTo = [account.user]
        message.references = ["ref1"]
        message.save( )

        let cdmessage1 = CdMessage.first()!
        let pepmessage = cdmessage1.pEpMessage()
        let cdmessage2 = CdMessage.create()
        cdmessage2.update(pEpMessage: pepmessage)

        XCTAssertEqual(cdmessage2, cdmessage1)
    }

    func testPEPMessageBuckets() {
        let session = PEPSession.init()
        let (identity, receiver1, receiver2, receiver3, _) = TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        var pepMail = PEPMessage()
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = NSArray.init(array: [identity, receiver1])
        pepMail[kPepCC] = NSArray.init(array: [identity, receiver2])
        pepMail[kPepBCC] = NSArray.init(array: [identity, receiver3])
        pepMail[kPepShortMessage] = "Subject" as AnyObject
        pepMail[kPepLongMessage] = "Some body text" as AnyObject

        let (encrypted, unencrypted) = session.bucketsForPEPMessage(pepMail as PEPMessage)
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

    func testPEPMessageBucketsWithSingleEncryptedMail() {
        let session = PEPSession.init()
        let (identity, _, _, _, _) = TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        let pepMail: NSMutableDictionary = [:]
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = [identity]
        pepMail[kPepShortMessage] = "Subject"
        pepMail[kPepLongMessage] = "Some body text"

        let (encrypted, unencrypted) = session.bucketsForPEPMessage(
            pepMail as NSDictionary as! PEPMessage)
        XCTAssertEqual(encrypted.count, 1)
        XCTAssertEqual(unencrypted.count, 0)

        XCTAssertEqual(encrypted[0][kPepTo] as? NSArray, [identity])
        XCTAssertNil(encrypted[0][kPepCC])
        XCTAssertNil(encrypted[0][kPepBCC])
    }

    func testPEPMessageBuckets2() {
        let session = PEPSession.init()

        // Import public key for receiver4
        TestUtil.importKeyByFileName(
            session, fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

        let (identity, receiver1, receiver2, receiver3, receiver4) =
            TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        let pepMail: NSMutableDictionary = [:]
        pepMail[kPepFrom] = identity
        pepMail[kPepTo] = [identity, receiver1]
        pepMail[kPepCC] = [identity, receiver2]
        pepMail[kPepBCC] = [identity, receiver3, receiver4]
        pepMail[kPepShortMessage] = "Subject"
        pepMail[kPepLongMessage] = "Some body text"

        let (encrypted, unencrypted) = session.bucketsForPEPMessage(
            pepMail as NSDictionary as! PEPMessage)
        XCTAssertEqual(encrypted.count, 3)
        XCTAssertEqual(unencrypted.count, 1)

        if encrypted.count == 3 {
            XCTAssertEqual(encrypted[0][kPepTo] as? NSArray, [identity])
            XCTAssertEqual(encrypted[0][kPepCC] as? NSArray, [identity])
            XCTAssertEqual(encrypted[0][kPepBCC] as? NSArray, [])

            XCTAssertEqual(encrypted[1][kPepTo] as? NSArray, [])
            XCTAssertEqual(encrypted[1][kPepCC] as? NSArray, [])
            XCTAssertEqual(encrypted[1][kPepBCC] as? NSArray, [identity])

            XCTAssertEqual(encrypted[2][kPepTo] as? NSArray, [])
            XCTAssertEqual(encrypted[2][kPepCC] as? NSArray, [])
            XCTAssertEqual(encrypted[2][kPepBCC] as? NSArray, [receiver4])
        }

        XCTAssertEqual(unencrypted[0][kPepTo] as? NSArray, [receiver1])
        XCTAssertEqual(unencrypted[0][kPepCC] as? NSArray, [receiver2])
        XCTAssertEqual(unencrypted[0][kPepBCC] as? NSArray, [receiver3])
    }

    func tryDecryptMessage(message: NSDictionary, myID: String, session: PEPSession) {
        var pepDecryptedMessage: NSDictionary? = nil
        var keys: NSArray?
        let _ = session.decryptMessageDict(message as! PEPMessage,
                                           dest: &pepDecryptedMessage, keys: &keys)
        if let decMsg = pepDecryptedMessage {
            XCTAssertEqual(decMsg[kPepID] as? String, myID)
        } else {
            XCTFail()
        }
    }

    func testMessageIDAfterEncrypt() {
        let testData = TestData()
        let myself = testData.createWorkingIdentity(number: 0)
        let myID = "myID"
        let dict = [
            kPepFrom: myself as AnyObject,
            kPepTo: NSArray(array: [myself]),
            kPepID: myID as AnyObject,
            kPepShortMessage: "Some Subject" as AnyObject,
            kPepLongMessage: "The text body" as AnyObject,
            kPepOutgoing: NSNumber(booleanLiteral: true)
        ] as PEPMessage

        let session = PEPSession()

        session.mySelf(NSMutableDictionary(dictionary: myself))

        let (status1, encMsg1) = session.encrypt(
            pEpMessageDict: dict, forIdentity: myself)
        XCTAssertEqual(status1, PEP_STATUS_OK)
        if let theEncMsg = encMsg1 {
            XCTAssertEqual(theEncMsg[kPepID] as? String, myID)
            tryDecryptMessage(message: theEncMsg, myID:myID, session: session)
        } else {
            XCTFail()
        }

        let (status2, encMsg2) = session.encrypt(
            pEpMessageDict: dict)
        XCTAssertEqual(status2, PEP_STATUS_OK)
        if let theEncMsg = encMsg2 {
            XCTAssertEqual(theEncMsg[kPepID] as? String, myID)
            tryDecryptMessage(message: theEncMsg, myID: myID, session: session)
        } else {
            XCTFail()
        }
    }
}
