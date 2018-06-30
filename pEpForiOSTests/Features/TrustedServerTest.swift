//
//  TrustedServerTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 25.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class TrustedServerTest: CoreDataDrivenTestBase {
    var cdAccount2: CdAccount!

    override func setUp() {
        super.setUp()
        let session = PEPSession()
        // Account 1
        cdAccount.identity?.userName = "unittest.ios.3"
        cdAccount.identity?.userID = "unittest.ios.3_ID"
        cdAccount.identity?.address = "unittest.ios.3@peptest.ch"
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_3_peptest_ch_550A_9E62_6822_040E_57CB_151A_651C_4A5D_B15B_77A3_sec.asc")
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_3_peptest_ch_550A_9E62_6822_040E_57CB_151A_651C_4A5D_B15B_77A3_pub.asc")
        try! session.setOwnKey(cdAccount.identity!.pEpIdentity(),
                               fingerprint: "550A9E626822040E57CB151A651C4A5DB15B77A3")
        // Account 2
        cdAccount2 = SecretTestData().createWorkingCdAccount(number: 1)
        cdAccount2.identity?.userName = "unittest.ios.4"
        cdAccount2.identity?.userID = "unittest.ios.4_ID"
        cdAccount2.identity?.address = "unittest.ios.4@peptest.ch"
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_4_peptest_ch_66AF_5804_A879_1E01_B407_125A_CAF0_D838_1542_49C4_sec.asc")
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_4_peptest_ch_66AF_5804_A879_1E01_B407_125A_CAF0_D838_1542_49C4_pub.asc")
        try! session.setOwnKey(cdAccount2.identity!.pEpIdentity(),
                               fingerprint: "66AF 5804 A879 1E01 B407 125A CAF0 D838 1542 49C4")

        TestUtil.skipValidation()
        Record.saveAndWait()

        cdAccount.createRequiredFoldersAndWait(testCase: self)
        cdAccount2.createRequiredFoldersAndWait(testCase: self)

        Message.swizzleIsTrustedServerToAlwaysTrue()
    }

//    override func tearDown() {
//        Message.unswizzleIsTrustedServer() //IOS-33: Check if unswizzling is required.
//        super.tearDown()
//    }


    func testMailSend() {
        guard let id1 = cdAccount.identity, let id2 = cdAccount2.identity else {
            XCTFail("We all loose identity ...")
            return
        }

        // Sync both acocunts and remember what we got before starting the actual test
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)
//        let msgsInSentAccount1Before = cdAccount.allMessages(inFolderOfType: .sent, sendFrom: id1)
//        let msgsInInboxAccount2Before = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id1)

        // Create mail(s) from cdAccount to cdAccount2 ...
        let numMailsToSend = 1
        let sendKey = try! TestUtil.createOutgoingMails(cdAccount: cdAccount,
                                                        fromIdentity: id2,
                                                        toIdentity: id1,
                                                        testCase: self,
                                                        numberOfMails: numMailsToSend,
                                                        withAttachments: false)
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)

        //
        let mailsToSend = try! TestUtil.createOutgoingMails(cdAccount: cdAccount,
                                                            fromIdentity: id1,
                                                            toIdentity: id2,
                                                            testCase: self,
                                                            numberOfMails: numMailsToSend,
                                                            withAttachments: false)
        XCTAssertEqual(mailsToSend.count, numMailsToSend)
        Record.saveAndWait()

        // ... send them.
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)



    }

    //        let msgsInSentAccount1After = cdAccount.allMessages(inFolderOfType: .sent, sendFrom: id1)
    //            .sorted { (msg1: CdMessage, msg2: CdMessage) -> Bool in
    //                return msg1.sent! < msg2.sent!
    //            }
    //            .map { $0.message()! }
    //        let newMailsStartIdx = msgsInSentAccount1After.count - numMailsToSend
    //        let newMailsEndIdx = msgsInSentAccount1After.count - 1
    //        let mailsToSendInSentFolder = msgsInSentAccount1After[newMailsStartIdx...newMailsEndIdx]
    //        // TODO: add test for sent folder
    //
    //
    //        let msgsInInboxAccount2After = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id1)
    //
    //        XCTAssertEqual(msgsInSentAccount1After.count,
    //                       msgsInSentAccount1Before.count + numMailsToSend,
    //                       "Mails to send are in sent folder of sender")
    //        let theFetchedOne = 1
    //        let theOneToReUpload = 1
    //        XCTAssertEqual(msgsInInboxAccount2After.count,
    //                       msgsInInboxAccount2Before.count + theFetchedOne + theOneToReUpload)
    //
    //        // Sync again to append messages to reupload
    //        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)
    //        let msgsInInboxAccount2AfterReupload = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id1)

    //IOS-1141
    //    func testAnonymizedRating() {
    //        // Setup 2 accounts
    //        cdAccount.createRequiredFoldersAndWait(testCase: self)
    //        Record.saveAndWait()
    //
    //        let cdAccount2 = SecretTestData().createWorkingCdAccount(number: 1)
    //        TestUtil.skipValidation()
    //        Record.saveAndWait()
    //        cdAccount2.createRequiredFoldersAndWait(testCase: self)
    //        Record.saveAndWait()
    //
    //        guard let id1 = cdAccount.identity, let id2 = cdAccount2.identity else {
    //            XCTFail("We all loose identity ...")
    //            return
    //        }
    //
    //        // Sync both acocunts and remember what we got before starting the actual test
    //        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)
    //        let msgsInSentAccount1Before = cdAccount.allMessages(inFolderOfType: .sent, sendFrom: id1)
    //
    //        // Create mail(s) from cdAccount to cdAccount2 ...
    //        let numMailsToSend = 1
    //        let mailsToSend = try! TestUtil.createOutgoingMails(cdAccount: cdAccount,
    //                                                            fromIdentity: id1,
    //                                                            toIdentity: id2,
    //                                                            testCase: self,
    //                                                            numberOfMails: numMailsToSend,
    //                                                            withAttachments: false)
    //        XCTAssertEqual(mailsToSend.count, numMailsToSend)
    //        Record.saveAndWait()
    //
    //        // ... and send them.
    //        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)
    //
    //        // Now let's see what we got.
    //        let msgsInSentAccount1After = cdAccount.allMessages(inFolderOfType: .sent, sendFrom: id1)
    //            .sorted { (msg1: CdMessage, msg2: CdMessage) -> Bool in
    //                return msg1.sent! < msg2.sent!
    //            }
    //            .map { $0.message()! }
    //        let newMailsStartIdx = msgsInSentAccount1After.count - numMailsToSend
    //        let newMailsEndIdx = msgsInSentAccount1After.count - 1
    //        let mailsToSendInSentFolder = msgsInSentAccount1After[newMailsStartIdx...newMailsEndIdx]
    //        XCTAssertEqual(msgsInSentAccount1After.count,
    //                       msgsInSentAccount1Before.count + numMailsToSend,
    //                       "Send mails are in sent folder")
    //        for msg in mailsToSendInSentFolder {
    //            let originalRating = msg.getOriginalRatingHeaderRating()
    //            let rating = msg.pEpRating()
    //            XCTAssertTrue(originalRating != PEP_rating_trusted_and_anonymized)
    //            XCTAssertTrue(rating != PEP_rating_trusted_and_anonymized)
    //        }
    //    }
}
