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

/// Test suite for re-uploading (or not) messages.
/// Find details here: https://dev.pep.security/Common%20App%20Documentation/Trusted_Untrusted_Server_Demystified
class ReUploadTest: CoreDataDrivenTestBase {
    let folderTypesEvaluatedByTests = [FolderType.inbox, .sent]

    override func setUp() {
        super.setUp()
        // Setup soley mark all mails on server deleted.
        setupSenderAccount()
        markAllMessagesOnServerDeleted()
        // And start from scratch
        tearDownWithoutBotheringXCT()
        setupWithoutBotheringXCT()
        setupSenderAccount()
    }

    // MARK: - Trusted Server

    /*
    Send unencrypted
     - Send unencrypted mail
     Check: Is msg in Sent folder unencrypted (*not* encrypted for self)
     */
    func testSendUnencrypted_trustedServer() {
        assert(senderTrusted: true,
               receiverTrusted: false,
               sendEncrypted: false,
               expectedSenderRatingOnServerEncrypted: false,
               expectedSenderRatingToDisplayEncrypted: false,
               expectedReceiverRatingOnServerEncrypted: false,
               expectedReceiverRatingToDisplayEncrypted: false)
    }

    /*
     Receive unencrypted
     - Receive unencrypted mail
     - Mail is in Inbox unencrypted (*not* encrypted for self)
     - Is msg in Inbox is grey
     */
    func testReceiveUnencrypted_trustedServer() {
        assert(senderTrusted: false,
               receiverTrusted: true,
               sendEncrypted: false,
               expectedSenderRatingOnServerEncrypted: true,
               expectedSenderRatingToDisplayEncrypted: false,
               expectedReceiverRatingOnServerEncrypted: false,
               expectedReceiverRatingToDisplayEncrypted: false)
    }

    /*
     Send enrcypted
     - Send encrypted mail
     Check:
     - Message is sent encrypted (Inbox receiver)
     - msg in Sent folder is unencrypted (*not* encrypted for self)
     - msg in Sent folder is yelow (*not* grey)
     */
    func testSendEncrypted_trustedServer() {
        assert(senderTrusted: true,
               receiverTrusted: false,
               sendEncrypted: true,
               expectedSenderRatingOnServerEncrypted: false,
               expectedSenderRatingToDisplayEncrypted: true,
               expectedReceiverRatingOnServerEncrypted: true,
               expectedReceiverRatingToDisplayEncrypted: true)
    }

    /*
     Receive encrypted
     - Receive encrypted mail
     - Mail is in Inbox unencrypted (*not* encrypted for self)
     - msg in Inbox is yellow
     */
    func testReceiveEncrypted_trustedServer() {
        assert(senderTrusted: false,
               receiverTrusted: true,
               sendEncrypted: true,
               expectedSenderRatingOnServerEncrypted: true,
               expectedSenderRatingToDisplayEncrypted: true,
               expectedReceiverRatingOnServerEncrypted: false,
               expectedReceiverRatingToDisplayEncrypted: true)
    }

    // MARK: - Untrusted Server

    /*
     Send unencrypted
     - Send unencrypted mail
     Check: Message in Sent folder is encrypted (for self)
     */
    func testSendUnencrypted_untrustedServer() {
        assert(senderTrusted: false,
               receiverTrusted: false,
               sendEncrypted: false,
               expectedSenderRatingOnServerEncrypted: true,
               expectedSenderRatingToDisplayEncrypted: false,
               expectedReceiverRatingOnServerEncrypted: false,
               expectedReceiverRatingToDisplayEncrypted: false)
    }

    /*
     Receive unencrypted
     - Receive unencrypted mail
     - Mail is in Inbox unencrypted (*not* encrypted for self)
     - Is msg in Inbox is grey
     */
    func testReceiveUnencrypted_untrustedServer() {
        assert(senderTrusted: false,
               receiverTrusted: false,
               sendEncrypted: false,
               expectedSenderRatingOnServerEncrypted: true,
               expectedSenderRatingToDisplayEncrypted: false,
               expectedReceiverRatingOnServerEncrypted: false,
               expectedReceiverRatingToDisplayEncrypted: false)
    }

    /*
     Send enrcypted
     - Send encrypted mail
     Check:
     - Message is sent encrypted
     - Is msg in Sent folder encrypted (for self)
     - Is msg in Sent folder yellow (not grey)
     */
    func testSendEncrypted_untrustedServer() {
        assert(senderTrusted: false,
               receiverTrusted: false,
               sendEncrypted: true,
               expectedSenderRatingOnServerEncrypted: true,
               expectedSenderRatingToDisplayEncrypted: true,
               expectedReceiverRatingOnServerEncrypted: true,
               expectedReceiverRatingToDisplayEncrypted: true)
    }

    /*
     Receive encrypted (decryptable)
     - Receive encrypted mail
     - Mail is in Inbox (on server) encrypted (not reuploaded unencrypted)
     - msg color is yellow (not grey)
     */
    func testReceiveEncrypted_untrustedServer() {
        assert(senderTrusted: false,
               receiverTrusted: false,
               sendEncrypted: true,
               expectedSenderRatingOnServerEncrypted: true,
               expectedSenderRatingToDisplayEncrypted: true,
               expectedReceiverRatingOnServerEncrypted: true,
               expectedReceiverRatingToDisplayEncrypted: true)
    }

    // MARK: - HELPER

    // Similar to super.setup() but without bothering Xcode Test
    private func setupWithoutBotheringXCT() {
        XCTAssertTrue(PEPUtil.pEpClean())
        persistentSetup = PersistentSetup()
        let cdAccount = SecretTestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount
    }

    // Similar to super.tearDown() but without bothering Xcode Test
    private func tearDownWithoutBotheringXCT() {
        imapSyncData?.sync?.close()
        persistentSetup = nil
        PEPSession.cleanup()
    }

    // MARK: The actual test

    func assert(senderTrusted: Bool,
                receiverTrusted: Bool,
                sendEncrypted: Bool,
                expectedSenderRatingOnServerEncrypted: Bool,
                expectedSenderRatingToDisplayEncrypted: Bool,
                expectedReceiverRatingOnServerEncrypted: Bool,
                expectedReceiverRatingToDisplayEncrypted: Bool) {
        if senderTrusted {
            TestUtil.setServersTrusted(forCdAccount: cdAccount, testCase: self)
        }

        guard let sender = cdAccount.identity else {
                XCTFail("No identity")
                return
        }

        let receiver: CdIdentity
        if sendEncrypted {
            guard let tmpReceiver = createForeignReceiverIdentityKnownKey().cdIdentity() else {
                XCTFail("No identity")
                return
            }
            receiver = tmpReceiver
        } else {
            guard let tmpReceiver = createForeignReceiverIdentityNoKnownKey().cdIdentity() else {
                XCTFail("No identity")
                return
            }
            receiver = tmpReceiver
        }

        // Send mail and sync
        let sentMails = try! TestUtil.createOutgoingMails(cdAccount: cdAccount,
                                                          fromIdentity: sender,
                                                          toIdentity: receiver,
                                                          setSentTimeOffsetForManualOrdering: false,
                                                          testCase: self,
                                                          numberOfMails: 1,
                                                          withAttachments: false,
                                                          attachmentsInlined: false,
                                                          encrypt: false)
        XCTAssertEqual(sentMails.count, 1)
        guard let sentMail = sentMails.first, let sentUuid = sentMail.uuid else {
            XCTFail("Problem")
            return
        }
        TestUtil.makeFolderInteresting(folderType: .sent, cdAccount: cdAccount)
        TestUtil.syncAndWait(numAccountsToSync: 1, testCase: self, skipValidation: true)

        let sentFolder = TestUtil.cdFolder(ofType: .sent, in: cdAccount)
        guard let sentFolderName = sentFolder.name else {
            XCTFail("Problem")
            return
        }
        // Everything as expected on sender side?
        guard
            let cdMsg = CdMessage.search(uid: nil,
                                         uuid: sentUuid,
                                         folderName: sentFolderName,
                                         inAccount: cdAccount),
            let msg = cdMsg.message()
            else {
                XCTFail("Message not found")
                return
        }
        XCTAssertTrue(msg.uid > 0, "We fetched the message from server")

        let senderRatingOnServer = PEPUtil.pEpRatingFromInt(msg.pEpRatingInt)
        if expectedSenderRatingOnServerEncrypted {
            XCTAssertFalse(senderRatingOnServer == PEP_rating_unencrypted,
                           "assumed stored rating on sever")
        } else {
            XCTAssertTrue(senderRatingOnServer == PEP_rating_unencrypted,
                           "assumed stored rating on sever")
        }

        let senderRatingToDisplay = msg.pEpRating()
        if expectedSenderRatingToDisplayEncrypted {
            XCTAssertFalse(senderRatingToDisplay == PEP_rating_unencrypted,
                           "Color to display to user is correct")
        } else {
            XCTAssertTrue(senderRatingToDisplay == PEP_rating_unencrypted,
                          "Color to display to user is correct")
        }

        // Fine.

        // Now lets see on receiver side.
        guard let cdAccountReceiver = createAccountOfReceiver().cdAccount() else {
            XCTFail("No account")
            return
        }

        if receiverTrusted {
            TestUtil.setServersTrusted(forCdAccount: cdAccountReceiver, testCase: self)
        }
        // Fetch, maybe re-upload and fetch again.
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)

        // Check inbox for the received message
        let inbox = TestUtil.cdFolder(ofType: .inbox, in: cdAccountReceiver)
        guard let inboxFolderName = inbox.name else {
            XCTFail("Problem")
            return
        }
        guard
            let cdReceivedMsg = CdMessage.search(uid: nil,
                                                 uuid: sentUuid,
                                                 folderName: inboxFolderName,
                                                 inAccount: cdAccountReceiver,
                                                 includingDeleted: false),
            let receivedMsg = cdReceivedMsg.message()
            else {
                XCTFail("Message not found")
                return
        }

        XCTAssertTrue(receivedMsg.uid > 0, "We fetched the message from server")

        guard let receiverRatingOnServer = PEPUtil.pEpRatingFromInt(receivedMsg.pEpRatingInt) else {
            XCTFail("No rating.")
            return
        }
        if expectedReceiverRatingOnServerEncrypted {
            XCTAssertFalse(receiverRatingOnServer == PEP_rating_unencrypted,
                           "rating on sever")
        } else {
            XCTAssertTrue(receiverRatingOnServer == PEP_rating_unencrypted,
                          "rating on sever")
        }

        let receiverRatingToDisplay = receivedMsg.pEpRating()
        if expectedReceiverRatingToDisplayEncrypted {
            XCTAssertFalse(receiverRatingToDisplay == PEP_rating_unencrypted,
                           "Color to display to user is correct")
        } else {
            XCTAssertTrue(receiverRatingToDisplay == PEP_rating_unencrypted,
                          "Color to display to user is correct")
        }
    }

    // MARK: Account / Identity 1 (sender)

    private func setupSenderAccount() {
        // // Account on trusted server (sender)
        cdAccount.identity?.userName = "unittest.ios.3"
        cdAccount.identity?.userID = "unittest.ios.3_ID"
        cdAccount.identity?.address = "unittest.ios.3@peptest.ch"
        guard
            let cdServerImap = cdAccount.server(type: .imap),
            let imapCredentials = cdServerImap.credentials,
            let cdServerSmtp = cdAccount.server(type: .smtp),
            let smtpCredentials = cdServerSmtp.credentials else {
                XCTFail("Problem in setup")
                return
        }
        imapCredentials.loginName = "unittest.ios.3@peptest.ch"
        smtpCredentials.loginName = "unittest.ios.3@peptest.ch"
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_3_peptest_ch_550A_9E62_6822_040E_57CB_151A_651C_4A5D_B15B_77A3_sec.asc")
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_3_peptest_ch_550A_9E62_6822_040E_57CB_151A_651C_4A5D_B15B_77A3_pub.asc")
        try! session.setOwnKey(cdAccount.identity!.pEpIdentity(),
                               fingerprint: "550A9E626822040E57CB151A651C4A5DB15B77A3")
        TestUtil.skipValidation()
        Record.saveAndWait()
        cdAccount.createRequiredFoldersAndWait(testCase: self)
    }

    // MARK: Account / Identity 2 (receiver)

    private func createForeignReceiverIdentityNoKnownKey() -> Identity {
        let createe = Identity(address: "unittest.ios.4@peptest.ch",
                                 userID: "unittest.ios.4_ID",
                                 addressBookID: nil,
                                 userName: "unittest.ios.4",
                                 isMySelf: false)
        createe.save()
        return createe
    }

    private func createForeignReceiverIdentityKnownKey() -> Identity {
        let createe = Identity(address: "unittest.ios.4@peptest.ch",
                               userID: "unittest.ios.4_ID",
                               addressBookID: nil,
                               userName: "unittest.ios.4",
                               isMySelf: false)
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_4_peptest_ch_66AF_5804_A879_1E01_B407_125A_CAF0_D838_1542_49C4_pub.asc")
        createe.save()
        return createe
    }

    private func createOwnIdentityReceiverWithKeys() -> Identity {
        let createe = Identity(address: "unittest.ios.4@peptest.ch",
                               userID: "unittest.ios.4_ID",
                               addressBookID: nil,
                               userName: "unittest.ios.4",
                               isMySelf: true)
        createe.save()
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_4_peptest_ch_66AF_5804_A879_1E01_B407_125A_CAF0_D838_1542_49C4_sec.asc")
        try! TestUtil.importKeyByFileName(session,
                                          fileName:
            "unittest_ios_4_peptest_ch_66AF_5804_A879_1E01_B407_125A_CAF0_D838_1542_49C4_pub.asc")
        try! session.setOwnKey(createe.pEpIdentity(),
                               fingerprint: "66AF 5804 A879 1E01 B407 125A CAF0 D838 1542 49C4")
        return createe
    }

    private func createAccountOfReceiver(withKeys: Bool = true) -> Account {
        let receiver = createOwnIdentityReceiverWithKeys()
        // Get account from test data. We use it soley to take over server data.
        let tmpCdAccount = SecretTestData().createWorkingCdAccount(number: 1)
        guard
            let cdServerImap = tmpCdAccount.server(type: .imap),
            let imapCredentials = cdServerImap.credentials,
            let cdServerSmtp = tmpCdAccount.server(type: .smtp),
            let smtpCredentials = cdServerSmtp.credentials else {
               fatalError()
        }
        imapCredentials.loginName = receiver.address
        smtpCredentials.loginName = receiver.address

        let createe = tmpCdAccount.account()
        createe.user = receiver
        // Delete tmp account
        tmpCdAccount.identity?.delete()
        tmpCdAccount.delete()
        Record.saveAndWait()
        // Save new acount
        createe.save()
        TestUtil.skipValidation()
        guard let cdAccount = createe.cdAccount() else {
            XCTFail("No Accoount")
            return createe
        }
        cdAccount.createRequiredFoldersAndWait(testCase: self)
        return createe
    }

    // MARK: Prepare Messages on Server

    private func markAllMessagesDeleted(inCdAccount cdAccount: CdAccount) {
        var allMessages = [CdMessage]()
        for type in folderTypesEvaluatedByTests {
            allMessages.append(contentsOf: cdAccount.allMessages(inFolderOfType: type))
        }
        for cdMsg in allMessages {
            let msg = cdMsg.message()
            msg?.imapMarkDeleted()
        }
    }

    /// As we are using the same servers as trusted and untrusted depending on the test case, we
    /// must not fetch messages that already existed (from previous tests).
    private func markAllMessagesOnServerDeleted() {
        // Create receiver account temporarly to be able to delete all messages.
        // Without keys so the engine does not know it.
        guard let cdAccountReceiver = createAccountOfReceiver(withKeys: false).cdAccount() else {
            XCTFail("No account")
            return
        }
        makeFoldersInteresting(inCdAccount: cdAccountReceiver)
        makeFoldersInteresting(inCdAccount: cdAccount)
        // Fetch all messages.
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)
        // Mark all messages deleted ...
        markAllMessagesDeleted(inCdAccount: cdAccountReceiver)
        markAllMessagesDeleted(inCdAccount: cdAccount)
        // ... and propagate the changes to the servers
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)
        // Delete receiver account. Has to be freshly crated in tests.
        cdAccountReceiver.delete()
        Record.saveAndWait()
    }

    // MARK: Other

    private func makeFoldersInteresting(inCdAccount cdAccount: CdAccount) {
        for type in folderTypesEvaluatedByTests {
            TestUtil.makeFolderInteresting(folderType: type, cdAccount: cdAccount)
        }
    }
}
