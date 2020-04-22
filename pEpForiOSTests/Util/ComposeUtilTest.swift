//IOS-2241 DOES NOT COMPILE
////!!!: broke by merging IOS-1542.
//
////
////  ComposeUtilTest.swift
////  pEpForiOSTests
////
////  Created by Andreas Buff on 19.07.18.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//import MessageModel
//
//@testable import pEpForiOS
//
//class ComposeUtilTest: CoreDataDrivenTestBase {
//    var someone_A: Identity {
//        return createForeignIdentity(withId: "A")
//    }
//
//    var someone_B: Identity {
//        return createForeignIdentity(withId: "B")
//    }
//
//    var someone_C: Identity {
//        return createForeignIdentity(withId: "C")
//    }
//
//    var meCurrentlyUsedAccount: Identity {
//        return account.user
//    }
//
//    let noRecipients = [Identity]()
//
//    var meSomeUnusedAccount: Identity!
//
//    override func setUp() {
//        super.setUp()
//        cdAccount.createRequiredFoldersAndWait(testCase: self)
//        meSomeUnusedAccount = SecretTestData().createWorkingAccount(number: 1).user
//    }
//
//    // MARK: - REPLY
//
//    // MARK: FolderType !~ [.sent, .draft]
//
//    /*
//     1) From: Someone A To: Me X CC: ANY
//     - Reply Any Mailbox != sent:
//     algo: from -> to, to -> from
//     result: From: Me X To: Someone A CC: -- BCC: --
//     */
//    func testReply_inbox_fromSomeoneA_toMe_ccNone_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyFrom
//        // Original message
//        let folderType = FolderType.inbox
//        let sender = someone_A
//        let originalTos = [meCurrentlyUsedAccount]
//        let originalCcs = noRecipients
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = [sender]
//        let expectedCcs = noRecipients
//        let expectedBccs = noRecipients
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    func testReply_inbox_fromSomeoneA_toMe_ccSome_bccSome() {
//        let mode = ComposeUtil.ComposeMode.replyFrom
//        // Original message
//        let folderType = FolderType.inbox
//        let sender = someone_A
//        let originalTos = [meCurrentlyUsedAccount]
//        let originalCcs = [someone_B]
//        let originalBccs = [someone_C]
//        // Expected
//        let expectedTos = [sender]
//        let expectedCcs = noRecipients
//        let expectedBccs = noRecipients
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    // MARK: FolderType == .sent
//
//    /*
//     1) From: Me X To: Someone A CC: ANY BCC:. ANY
//     - Reply Any Mailbox == sent:
//     algo: from -> from, to -> to
//     result: From: Me X To: Someone A CC: -- BCC: --
//     */
//    func testReply_sent_fromSomeoneA_toMe_ccNone_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyFrom
//        // Original message
//        let folderType = FolderType.sent
//        let sender = meCurrentlyUsedAccount
//        let originalTos = [someone_A]
//        let originalCcs = noRecipients
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = originalTos
//        let expectedCcs = noRecipients
//        let expectedBccs = noRecipients
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    func testReply_sent_fromSomeoneA_toMe_ccSome_bccSome() {
//        let mode = ComposeUtil.ComposeMode.replyFrom
//        // Original message
//        let folderType = FolderType.sent
//        let sender = meCurrentlyUsedAccount
//        let originalTos = [someone_A]
//        let originalCcs = [someone_B]
//        let originalBccs = [someone_C]
//        // Expected
//        let expectedTos = originalTos
//        let expectedCcs = noRecipients
//        let expectedBccs = noRecipients
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    // MARK: - REPLY ALL
//
//     // MARK: FolderType !~ [.sent, .draft]
//
//    /*
//     From: Someone A To: Me X  CC: -- BCC: --
//     - ReplyAll Mailbox !~ [.sent, .drafts]:
//     algo: from -> me, to = from + (origTos - me)
//     expected: From: Me X To: Someone A  CC: -- BCC: --
//     */
//    func testReplyAll_inbox_fromSomeoneA_toMe_ccNone_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyAll
//        // Original message
//        let folderType = FolderType.inbox
//        let sender = someone_A
//        let originalTos = [meCurrentlyUsedAccount]
//        let originalCcs = noRecipients
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = [sender]
//        let expectedCcs = noRecipients
//        let expectedBccs = noRecipients
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    /*
//     From: Someone A To: Me X, someone B CC: -- BCC: --
//     - ReplyAll Mailbox !~ [.sent, .drafts]:
//     algo: from -> me, to = from + (origTos - me)
//     expected: From: Me X To: Someone A, someone B CC: --
//     */
//    func testReplyAll_inbox_fromSomeoneA_toSomeMeIncluded_ccNone_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyAll
//        // Original message
//        let folderType = FolderType.inbox
//        let sender = someone_A
//        let originalTos = [meCurrentlyUsedAccount, someone_B]
//        let originalCcs = noRecipients
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = [sender, someone_B]
//        let expectedCcs = noRecipients
//        let expectedBccs = noRecipients
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    /*
//     From: Someone A To: Me X  CC: someone B  BCC: --
//     - ReplyAll Mailbox !~ [.sent, .drafts]:
//     expected: From: Me X To: Someone A,  CC: someone B
//     */
//    func testReplyAll_inbox_fromSomeoneA_toMe_ccSomeMeNotIncluded_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyAll
//        // Original message
//        let folderType = FolderType.inbox
//        let sender = someone_A
//        let originalTos = [meCurrentlyUsedAccount]
//        let originalCcs = [someone_B]
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = [sender]
//        let expectedCcs = originalCcs
//        let expectedBccs = noRecipients
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    /*
//     From: Someone A To: someone B  CC: Me, someone C  BCC: --
//     - ReplyAll Mailbox !~ [.sent, .drafts]:
//     expected: From: Me X To: Someone A, someone_B,  CC: someone C
//     */
//    func testReplyAll_inbox_fromSomeoneA_toSomeoneB_ccSomeMeIncluded_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyAll
//        // Original message
//        let folderType = FolderType.inbox
//        let sender = someone_A
//        let originalTos = [someone_B]
//        let originalCcs = [meCurrentlyUsedAccount, someone_C]
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = [sender, someone_B]
//        let expectedCcs =  [someone_C]
//        let expectedBccs = noRecipients
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    // MARK: FolderType == .sent
//
//    /*
//     - ReplyAll Sent:
//     from -> from, to -> to, cc -> cc
//     */
//    func testReplyAll_sent_fromSomeoneA_toMe_ccNone_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyAll
//        // Original message
//        let folderType = FolderType.sent
//        let sender = someone_A
//        let originalTos = [meCurrentlyUsedAccount]
//        let originalCcs = noRecipients
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = originalTos
//        let expectedCcs = originalCcs
//        let expectedBccs = originalBccs
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    func testReplyAll_sent_fromSomeoneA_toSomeMeIncluded_ccNone_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyAll
//        // Original message
//        let folderType = FolderType.sent
//        let sender = someone_A
//        let originalTos = [meCurrentlyUsedAccount, someone_B]
//        let originalCcs = noRecipients
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = originalTos
//        let expectedCcs = originalCcs
//        let expectedBccs = originalBccs
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    func testReplyAll_sent_fromSomeoneA_toMe_ccSomeMeNotIncluded_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyAll
//        // Original message
//        let folderType = FolderType.sent
//        let sender = someone_A
//        let originalTos = [meCurrentlyUsedAccount]
//        let originalCcs = [someone_B]
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = originalTos
//        let expectedCcs = originalCcs
//        let expectedBccs = originalBccs
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    func testReplyAll_sent_fromSomeoneA_toSomeoneB_ccSomeMeIncluded_bccNone() {
//        let mode = ComposeUtil.ComposeMode.replyAll
//        // Original message
//        let folderType = FolderType.sent
//        let sender = someone_A
//        let originalTos = [someone_B]
//        let originalCcs = [meCurrentlyUsedAccount, someone_C]
//        let originalBccs = noRecipients
//        // Expected
//        let expectedTos = originalTos
//        let expectedCcs = originalCcs
//        let expectedBccs = originalBccs
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    // MARK: - Drafts
//
//    /*
//     expected: testee == original message
//     */
//    func testNormal_Drafts_fromSomeoneA_toSomeMeIncluded_ccSome_bccSome() {
//        let mode = ComposeUtil.ComposeMode.normal
//        // Original message
//        let folderType = FolderType.drafts
//        let sender = meCurrentlyUsedAccount
//        let originalTos = [meCurrentlyUsedAccount, someone_B]
//        let originalCcs = [someone_B]
//        let originalBccs = [someone_C]
//        // Expected
//        let expectedTos = originalTos
//        let expectedCcs = originalCcs
//        let expectedBccs = originalBccs
//
//        assertCorrectInitialRecipients(forReplyMode: mode,
//                                       originalMessageParentFolderType: folderType,
//                                       originalFrom: sender,
//                                       originalTos: originalTos,
//                                       originalCcs: originalCcs,
//                                       originalBccs: originalBccs,
//                                       expectedTos: expectedTos,
//                                       expectedCcs: expectedCcs,
//                                       expectedBccs: expectedBccs)
//    }
//
//    // MARK: - HELPER
//
//    private func assertCorrectInitialRecipients(forReplyMode mode: ComposeUtil.ComposeMode,
//                                                originalMessageParentFolderType type: FolderType,
//                                                originalFrom: Identity,
//                                                originalTos: [Identity],
//                                                originalCcs: [Identity],
//                                                originalBccs: [Identity],
//                                                expectedTos: [Identity],
//                                                expectedCcs: [Identity],
//                                                expectedBccs: [Identity]) {
//        let om = createOriginalMessage(inFolderOfType: type,
//                                       from: originalFrom,
//                                       tos: originalTos,
//                                       ccs: originalCcs,
//                                       bccs: originalBccs)
//
//        let expectedFrom = om.parent.account.user
//
//        assertRecipients(returnedForOriginalMessage: om,
//                         inComposeMode: mode,
//                         expectedFrom: expectedFrom,
//                         expectedTos: expectedTos,
//                         expectedCcs: expectedCcs,
//                         expectedBccs: expectedBccs)
//    }
//
//    private func assertRecipients(returnedForOriginalMessage om: Message,
//                                  inComposeMode mode: ComposeUtil.ComposeMode,
//                                  expectedFrom: Identity,
//                                  expectedTos: [Identity]?,
//                                  expectedCcs: [Identity]?,
//                                  expectedBccs: [Identity]?) {
//        // Testees
//        let from = ComposeUtil.initialFrom(composeMode: mode, originalMessage: om)
//        let tos = ComposeUtil.initialTos(composeMode: mode, originalMessage: om)
//        let ccs = ComposeUtil.initialCcs(composeMode: mode, originalMessage: om)
//        let bccs = ComposeUtil.initialBccs(composeMode: mode, originalMessage: om)
//        // Assert
//        XCTAssertEqual(from, expectedFrom)
//        assertEqualRecipients(ids1: tos, ids2: expectedTos)
//        assertEqualRecipients(ids1: ccs, ids2: expectedCcs)
//        assertEqualRecipients(ids1: bccs, ids2: expectedBccs)
//    }
//
//    private func assertEqualRecipients(ids1: [Identity]?, ids2: [Identity]?) {
//        let ids1 = ids1 ?? [Identity]()
//        let ids2 = ids2 ?? [Identity]()
//        XCTAssertEqual(ids1.count, ids2.count)
//
//        let uniqueIds1 = Set(ids1)
//        let uniqueIds2 = Set(ids2)
//        XCTAssertEqual(uniqueIds1.count, uniqueIds2.count)
//
//        for id1 in uniqueIds1 {
//            XCTAssertTrue(uniqueIds2.contains(id1))
//        }
//    }
//
//    private func createForeignIdentity(withId id: String) -> Identity {
//        let createe = Identity(address: id + "@" + id + ".com",
//                               userID: "TEST_ID_" + id,
//                               addressBookID: nil,
//                               userName: "TEST_USER_NAME_" + id,
//                               isMySelf: false)
//        return createe
//    }
//
//    private func createOriginalMessage(inFolderOfType type: FolderType,
//                                       from: Identity,
//                                       tos: [Identity],
//                                       ccs: [Identity],
//                                       bccs: [Identity]) -> Message {
//        guard let parentFolder = account.firstFolder(ofType: type) else {
//            fatalError("No folder." +
//                "Sorry, I had to crash here. The burn or buy bill would be too negative " +
//                "returning an Optional ")
//        }
//        let createe = Message(uuid: UUID().uuidString, parentFolder: parentFolder)
//        createe.from = from
//        createe.replaceTo(with: tos)
//        createe.replaceCc(with: ccs)
//        createe.replaceBcc(with: bccs)
//        let id = "Test Message - Created by ComposeUtilTest"
//        createe.shortMessage = id
//        createe.longMessage = id
//
//        return createe
//    }
//}
