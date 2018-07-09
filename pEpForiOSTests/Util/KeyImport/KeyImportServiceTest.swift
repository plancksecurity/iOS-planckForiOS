//
//  KeyImportServiceTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 04.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import MessageModel

@testable import pEpForiOS

class KeyImportServiceTest: CoreDataDrivenTestBase {
    var account: Account!
    var keyImportService: KeyImportService!
    var networkService: NetworkService {
        return NetworkService(keyImportListener: keyImportService)
    }
    let folderTypesEvaluatedByTests = [FolderType.inbox]

    /// KeyImportService *is* the KeyImportListener. But we want semantical seperation.
    var keyImportListener: KeyImportListenerProtocol {
        return keyImportService
    }
    /// Holds a strong reference. KeyImportService.delegate is weak.
    var observer: TestKeyImportServiceObserver?

    override func setUp() {
        super.setUp()
        setupAccount(device: Device.a)
        TestUtil.markAllMessagesOnServerDeleted(inFolderTypes: folderTypesEvaluatedByTests,
                                                for: [cdAccount])
        account = cdAccount.account()
        keyImportService = KeyImportService()
    }

    override func tearDown() {
        keyImportService = nil
        account = nil
        observer = nil
        super.tearDown()
    }

    // MARK: - KeyImportListenerProtocol Tests

    // MARK: newInitKeyImportRequestMessageArrived

    func testNewInitKeyImportRequestMessageArrived_headerSet() {
        assertHandleKeyImport(keyImportHeaderSet: true,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_no_color,
                              newImportMessageTimedOut: false,
                              expDelegateNewInitKeyImportRequestMessageArrived: true,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: true)
    }

    func testNewInitKeyImportRequestMessageArrived_headerSet_messageTimedOut() {
        assertHandleKeyImport(keyImportHeaderSet: true,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_no_color,
                              newImportMessageTimedOut: true,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    func testNewInitKeyImportRequestMessageArrived_headerNotSet() {
        assertHandleKeyImport(keyImportHeaderSet: false,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_no_color,
                              newImportMessageTimedOut: false,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    func testNewInitKeyImportRequestMessageArrived_headerNotSet_messageTimedOut() {
        assertHandleKeyImport(keyImportHeaderSet: false,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_no_color,
                              newImportMessageTimedOut: true,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    // MARK: newHandshakeRequestMessageArrived

    func testNewHandshakeRequestMessageArrived_headerSet() {
        assertHandleKeyImport(keyImportHeaderSet: true,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_yellow,
                              newImportMessageTimedOut: false,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: true,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: true)
    }

    func testNewHandshakeRequestMessageArrived_headerSet_messageTimedOut() {
        assertHandleKeyImport(keyImportHeaderSet: true,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_yellow,
                              newImportMessageTimedOut: true,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    func testNewHandshakeRequestMessageArrived_headerNotSet() {
        assertHandleKeyImport(keyImportHeaderSet: false,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_yellow,
                              newImportMessageTimedOut: false,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    func testNewHandshakeRequestMessageArrived_headerNotSet_messageTimedOut() {
        assertHandleKeyImport(keyImportHeaderSet: false,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_yellow,
                              newImportMessageTimedOut: true,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    func testNewHandshakeRequestMessageArrived_headerSet_pepGreen() {
        assertHandleKeyImport(keyImportHeaderSet: true,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_green,
                              newImportMessageTimedOut: false,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    // MARK: receivedPrivateKey

    func testReceivedPrivateKey_pEpColorGreen_flagReceived() {
        assertHandleKeyImport(keyImportHeaderSet: false,
                              ownPrivateKeyFlagReceived: true,
                              pepColor: PEP_color_green,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: true,
                              expectMessageHandledByKeyImportService: true)
    }

    func testReceivedPrivateKey_pEpColorGrey_flagReceived() {
        assertHandleKeyImport(keyImportHeaderSet: false,
                              ownPrivateKeyFlagReceived: true,
                              pepColor: PEP_color_no_color,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    func testReceivedPrivateKey_pEpColorGreen_noFlagReceived() {
        assertHandleKeyImport(keyImportHeaderSet: false,
                              ownPrivateKeyFlagReceived: false,
                              pepColor: PEP_color_green,
                              expDelegateNewInitKeyImportRequestMessageArrived: false,
                              expDelegateNewHandshakeRequestMessageArrived: false,
                              expectDelegateReceivedPrivateKeyCalled: false,
                              expectMessageHandledByKeyImportService: false)
    }

    // MARK: - KeyImportServiceProtocol

    // MARK: sendInitKeyImportMessage

    func testSendInitKeyImportMessage() {
        // Setup
        let expNewInitKeyImportRequestMessageArrivedCalled =
            expectation(description: "expNewInitKeyImportRequestMessageArrivedCalled")
        let expectedColor = PEP_color_no_color
        setupObserver(expNewInitKeyImportRequestMessageArrived:
            expNewInitKeyImportRequestMessageArrivedCalled,
                      expectedImportMessagePepColor: expectedColor)
        // Send message from Device A
        keyImportService.sendInitKeyImportMessage(forAccount: account)

//        // Wait until sent (ugly)
        sleep(3)

        switchTo(device: .b)

        // Fetch to receive the message.
        TestUtil.syncAndWait(networkService: networkService)
        // Did it trigger the delegate?
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    // MARK: - HELPER

    /// The actual handleKeyImport test.
    ///
    /// - Parameters:
    ///   - keyImportHeaderSet: whether or not to set a dummy FPR to "pEp-key-import" header of
    ///the test message
    ///   - ownPrivateKeyFlagReceived:  whether or not the Engine returned
    ///                      PEP_decrypt_flag_own_private_key when decrypting the test message
    ///   - pepColorGreen:  if true, the test message's pepRating represents PEP_color_green.
    ///                     else the test message's pepRating represents PEP_color_none.
    ///   - newImportMessageTimedOut: if true, the test message is too old to fulfil TTL
    ///   - expDelegateNewInitKeyImportRequestMessageArrived: if true we assert the
    ///                     KeyImportServiceDelegates `newInitKeyImportRequestMessageArrived`method
    ///                     is called.
    ///                     If false we assert it is *not* called.
    ///   - expDelegateNewHandshakeRequestMessageArrived: if true we assert the
    ///                     KeyImportServiceDelegates `newHandshakeRequestMessageArrived`method is
    ///                     called.
    ///                     If false we assert it is *not* called.
    ///   - expectDelegateReceivedPrivateKeyCalled: if true we assert the KeyImportServiceDelegates
    ///                     `receivedPrivateKey`method is called. If false we assert it is *not*
    ///                     called.
    ///   - expectMessageHandledByKeyImportService: whether or not we expect that the test message
    ///                     should be handled by KeyImportListener
    func assertHandleKeyImport(keyImportHeaderSet: Bool,
                ownPrivateKeyFlagReceived: Bool,
                pepColor: PEP_color,
                newImportMessageTimedOut: Bool = false,
                expDelegateNewInitKeyImportRequestMessageArrived: Bool,
                expDelegateNewHandshakeRequestMessageArrived: Bool,
                expectDelegateReceivedPrivateKeyCalled: Bool,
                expectMessageHandledByKeyImportService: Bool) {
        // Setup
        let expNewInitKeyImportRequestMessageArrivedCalled =
            expDelegateNewInitKeyImportRequestMessageArrived ?
            expectation(description: "expNewInitKeyImportRequestMessageArrivedCalled") : nil

        let expNewHandshakeRequestMessageArrivedCalled =
            expDelegateNewHandshakeRequestMessageArrived ?
            expectation(description: "expNewHandshakeRequestMessageArrivedCalled") : nil

        let expReceivedPrivateKeyCalled = expectDelegateReceivedPrivateKeyCalled ?
            expectation(description: "expReceivedPrivateKeyCalled") : nil

        let flagReturnedByEngine =
            ownPrivateKeyFlagReceived ? PEP_decrypt_flag_own_private_key : PEP_decrypt_flag_none

        setupObserver(expNewInitKeyImportRequestMessageArrived:
            expNewInitKeyImportRequestMessageArrivedCalled,
                      expNewHandshakeRequestMessageArrived:
            expNewHandshakeRequestMessageArrivedCalled,
                      expReceivedPrivateKey: expReceivedPrivateKeyCalled,
                      expectedImportMessagePepColor: pepColor)

        // We received a message ...
        let msg = createMessage(pEpKeyImportHeaderSet: keyImportHeaderSet,
                                pEpColor: pepColor,
                                timedOut: newImportMessageTimedOut)
        // ... and inform the listener.
        let isHandledByKeyImporter = keyImportListener.handleKeyImport(forMessage: msg,
                                                                       flags: flagReturnedByEngine)
        if expectMessageHandledByKeyImportService {
            XCTAssertTrue(isHandledByKeyImporter)
        } else {
            XCTAssertFalse(isHandledByKeyImporter)
        }

        let thereAreExpectationsToWaitFor = expNewInitKeyImportRequestMessageArrivedCalled != nil ||
            expNewHandshakeRequestMessageArrivedCalled != nil ||
            expReceivedPrivateKeyCalled != nil
        if  thereAreExpectationsToWaitFor {
            waitForExpectations(timeout: TestUtil.waitTime) { (error) in
                XCTAssertNil(error)
            }
        }
    }

    private func setupObserver(
        expNewInitKeyImportRequestMessageArrived: XCTestExpectation? = nil,
        expNewHandshakeRequestMessageArrived: XCTestExpectation? = nil,
        expReceivedPrivateKey: XCTestExpectation? = nil,
        expectedImportMessagePepColor: PEP_color? = nil) {
        observer =
            TestKeyImportServiceObserver(expNewInitKeyImportRequestMessageArrived:
                expNewInitKeyImportRequestMessageArrived,
                                         expNewHandshakeRequestMessageArrived:
                expNewHandshakeRequestMessageArrived,
                                         expReceivedPrivateKey: expReceivedPrivateKey)
        keyImportService.delegate = observer
    }

    /// Creates a test message.
    ///
    /// - Parameters:
    ///   - pEpKeyImportHeaderSet: whether or not to set a dummy FPR to "pEp-key-import" header
    ///   - pEpColor:   pEpColor to set PE_rating for.
    ///                 If given pEpColor is not in [green], grey is set
    ///   - newImportMessageTimedOut: if true `received` date of the message is before valid TTL,
    ///                 otherwize `received` date is now
    /// - Returns: test message
    private func createMessage(pEpKeyImportHeaderSet: Bool = false,
                               pEpColor: PEP_color = PEP_color_no_color,
                               timedOut: Bool = false) -> Message {
        guard let inbox = cdAccount.account().folder(ofType: .inbox) else {
            XCTFail("No inbox")
            fatalError("Sorry for crashing. " +
                "Should never happen and I want to avoid returning an Optional")
        }
        let msg = Message(uuid: "KeyImportServiceTestMessage_" + UUID().uuidString,
                          parentFolder: inbox)
        msg.received = timedOut ? Date() - KeyImportService.ttlKeyImportMessages - 1 : Date()

        if pEpKeyImportHeaderSet {
            let dummyFpr = "666F 666F 666F 666F 666F 666F 666F 666F 666F 666F"
            msg.optionalFields[KeyImportService.Header.pEpKeyImport.rawValue] = dummyFpr
        }
        if pEpColor == PEP_color_green {
            msg.pEpRatingInt = Int(PEP_rating_trusted.rawValue)
        } else if pEpColor == PEP_color_yellow {
            msg.pEpRatingInt = Int(PEP_rating_reliable.rawValue)
        } else {
            msg.pEpRatingInt = Int(PEP_rating_unencrypted.rawValue)
        }
        return msg
    }

    // MARK: Setup

    // In key import tests, we switch inbetween two devices with the same account but different
    // keys.
    // This is to identify the devices.
    private enum Device {
        case a
        case b
    }

    private func fingerprint(device: Device) -> String {
        switch device {
        case .a:
            return "550A9E626822040E57CB151A651C4A5DB15B77A3"
        case .b:
            return "D0F3567105D4BBF10A547F3C0D891B18333155C5"
        }
    }

    private func keyFileName(device: Device) -> String {
        switch device {
        case .a:
            return "unittest_ios_3_peptest_ch_550A_9E62_6822_040E_57CB_151A_651C_4A5D_B15B_77A3_"
        case .b:
            return "device_B_unittest_ios_3_D0F3_5671_05D4_BBF1_0A54_7F3C_0D89_1B18_3331_55C5_"
        }
    }
    private func setupAccount(device: Device) {
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

        let filenamePub = keyFileName(device: device) + "pub.asc"
        let filenameSec = keyFileName(device: device) + "sec.asc"
        let fpr = fingerprint(device: device)
        try! TestUtil.importKeyByFileName(session,
                                          fileName: filenameSec)
        try! TestUtil.importKeyByFileName(session,
                                          fileName: filenamePub)
        try! session.setOwnKey(cdAccount.identity!.pEpIdentity(),
                               fingerprint: fpr)

        TestUtil.skipValidation()
        Record.saveAndWait()
        cdAccount.createRequiredFoldersAndWait()
    }

    private func switchTo(device: Device) {
        XCTAssertTrue(PEPUtil.pEpClean())
        setupAccount(device: device)
    }

//    private func resetMyKey() {
//        XCTAssertTrue(PEPUtil.pEpClean())
//        do {
//            try PEPSession().mySelf(account.user.pEpIdentity())
//        } catch {
//            XCTFail("Problem")
//        }
//    }
}

class TestKeyImportServiceObserver: KeyImportServiceDelegate {

    let expNewInitKeyImportRequestMessageArrived: XCTestExpectation?
    let expNewHandshakeRequestMessageArrived: XCTestExpectation?
    let expReceivedPrivateKey: XCTestExpectation?

    /// Init observer with what to expect.
    /// If no expectation is passed for a method, we expect that method must not be called.
    init(expNewInitKeyImportRequestMessageArrived: XCTestExpectation? = nil,
         expNewHandshakeRequestMessageArrived: XCTestExpectation? = nil,
         expReceivedPrivateKey: XCTestExpectation? = nil) {
        self.expNewInitKeyImportRequestMessageArrived = expNewInitKeyImportRequestMessageArrived
        self.expNewHandshakeRequestMessageArrived = expNewHandshakeRequestMessageArrived
        self.expReceivedPrivateKey = expReceivedPrivateKey
    }

    func newInitKeyImportRequestMessageArrived(message: Message) {
        if let exp = expNewInitKeyImportRequestMessageArrived {
            // Must be grey
            XCTAssertEqual(message.pEpColor(), PEP_color_no_color)
            // Asset message got deleted in MM ...
            XCTAssertTrue(message.imapFlags?.deleted ?? false)
            // ... and CD
            let cdMessage = CdMessage.search(message: message)
            XCTAssertTrue(cdMessage?.imapFields().imapFlags().deleted ?? false)

            exp.fulfill()
        } else {
            XCTFail("method called unexpectedly.")
        }
    }

    func newHandshakeRequestMessageArrived(message: Message) {
        if let exp = expNewHandshakeRequestMessageArrived {
            // Must be yellow
            XCTAssertEqual(message.pEpColor(), PEP_color_yellow)
            // Asset message got deleted in MM ...
            XCTAssertTrue(message.imapFlags?.deleted ?? false)
            // ... and CD
            let cdMessage = CdMessage.search(message: message)
            XCTAssertTrue(cdMessage?.imapFields().imapFlags().deleted ?? false)

            exp.fulfill()
        } else {
            XCTFail("method called unexpectedly.")
        }
    }

    func receivedPrivateKey(forAccount account: Account) {
        if let exp = expReceivedPrivateKey {
            exp.fulfill()
        } else {
            XCTFail("method called unexpectedly.")
        }
    }

    func errorOccurred(error: Error) {
        XCTFail("We don't expect errors.")
    }
}
