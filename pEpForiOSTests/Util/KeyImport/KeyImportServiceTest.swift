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
    /// Holds a strong reference. KeyImportService.unitTestDelegate is weak.
    var unitTestCallbackReceiver: UnitTestDelegateKeyImportService?

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
        unitTestCallbackReceiver = nil
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
         // Send message from Device A
        let expDidSend = expectation(description: "expDidSend")
        setupUnitTestCallbackReceiver(with: expDidSend)
        keyImportService.sendInitKeyImportMessage(forAccount: account)
        waitForExpectations(timeout: TestUtil.waitTime)

        // Lets see if device B reacts correctly
        switchTo(device: .b)

        let expNewInitKeyImportRequestMessageArrivedCalled =
            expectation(description: "expNewInitKeyImportRequestMessageArrivedCalled")
        setupObserver(expNewInitKeyImportRequestMessageArrived:
            expNewInitKeyImportRequestMessageArrivedCalled)

        // Fetch to receive the message.
        TestUtil.syncAndWait(networkService: networkService)
        // Did it trigger the delegate?
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    // MARK: sendHandshakeRequestMessage

    func testSendHandshakeRequestMessage() {
        // Device A sent device B an InitKeyImport message.
        // We are on device B and react.
        switchTo(device: .b)
        // We know the pub key and the FPR of device A already
        importPubKey(of: .a)
        let fpr = fingerprint(device: .a)

        // Send HandshakeRequest message (from Device B)
        let expDidSend = expectation(description: "expDidSend")
        setupUnitTestCallbackReceiver(with: expDidSend)
        keyImportService.sendHandshakeRequest(forAccount: account, fpr: fpr)
        waitForExpectations(timeout: TestUtil.waitTime)

        // Lets see if device A reacts correctly
        switchTo(device: .a)

        let expDelegateNewHandshakeRequestMessageArrivedCalled =
            expectation(description: "expDelegateNewHandshakeRequestMessageArrivedCalled")
        setupObserver(expNewHandshakeRequestMessageArrived:
            expDelegateNewHandshakeRequestMessageArrivedCalled)

        // Fetch to receive the message.
        TestUtil.syncAndWait(networkService: networkService)
        // Did it trigger the delegate?
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    // MARK: sendOwnPrivateKey

//    func testSendOwnPrivateKey() {
//        // Device A sent device B an InitKeyImport message.
//        // Device B sent handshake request to device A
//        // Both devices did handshake
//
//        // We are on device A.
//        // We know pub key and FPR of device B already. Also we did handshake.
//        importPubKey(of: .b)
//        let fprB = fingerprint(device: .b)
//        let identityB = account.user.pEpIdentity()
//        identityB.fingerPrint = fprB
//        do {
//            try PEPSession().trustPersonalKey(identityB)
//        } catch {
//            XCTFail("I do not trust you!")
//        }
//
//        // Now we send our private key. (from device A)
//        let expDidSend = expectation(description: "expDidSend")
//        setupUnitTestCallbackReceiver(with: expDidSend)
//        keyImportService.sendOwnPrivateKey(forAccount: account, fpr: fprB)
//        waitForExpectations(timeout: TestUtil.waitTime)
//
//        // Lets see if device B reacts correctly
//        switchTo(device: .b)
//        // We already know pub key and FPR of device A and did handshake.
//        let fprA = fingerprint(device: .a)
//        let identityA = account.user.pEpIdentity()
//        identityA.fingerPrint = fprA
//        do {
//            try PEPSession().trustPersonalKey(identityA)
//        } catch {
//            XCTFail("I do not trust you!")
//        }
//
//        let expDelegateReceivedPrivateKeyCalled =
//            expectation(description: "expDelegateReceivedPrivateKeyCalled")
//        setupObserver(expReceivedPrivateKey: expDelegateReceivedPrivateKeyCalled)
//
//        // Fetch to receive the message.
//        TestUtil.syncAndWait(networkService: networkService)
//        // Did it trigger the delegate?
//        waitForExpectations(timeout: TestUtil.waitTime)
//    }

    // MARK: full key import cycle
//
//    func testFullKeyImportProcess() {
//        // **********************************
//        // Send Init message from Device A
//        // **********************************
//        var expDidSend = expectation(description: "expDidSend")
//        setupUnitTestCallbackReceiver(with: expDidSend)
//        keyImportService.sendInitKeyImportMessage(forAccount: account)
//        waitForExpectations(timeout: TestUtil.waitTime)
//
//        // **********************************
//        // Receive it on device B
//        // **********************************
//        switchTo(device: .b)
//
//        let expNewInitKeyImportRequestMessageArrivedCalled =
//            expectation(description: "expNewInitKeyImportRequestMessageArrivedCalled")
//        setupObserver(expNewInitKeyImportRequestMessageArrived:
//            expNewInitKeyImportRequestMessageArrivedCalled)
//
//        // Fetch to receive the message.
//        TestUtil.syncAndWait(networkService: networkService)
//        // Did it trigger the delegate?
//        waitForExpectations(timeout: TestUtil.waitTime)
//        // Has correctly be received.
////        // Thus the pub key of device A should now be know to device B
////        importPubKey(of: Device.a)
//
//        // **********************************
//        // Device B sends handshake request
//        // **********************************
//        expDidSend = expectation(description: "expDidSend")
//        setupUnitTestCallbackReceiver(with: expDidSend)
//        let fprDeviceA = fingerprint(device: .a)
//        let fprDeviceB = fingerprint(device: .b)
//        keyImportService.sendHandshakeRequest(forAccount: account, fpr: fprDeviceB)
//        waitForExpectations(timeout: TestUtil.waitTime)
//
//        // **********************************
//        // Device A & B confirm FPRs (do handshake)
//        // **********************************
//        let pepIdentityA = account.user.pEpIdentity()
//        pepIdentityA.fingerPrint = fingerprint(device: .a)
//        let pepIdentityB = account.user.pEpIdentity()
//        pepIdentityB.fingerPrint = fingerprint(device: .b)
//        session.trustPersonalKey(<#T##identity: PEPIdentity##PEPIdentity#>)
//
//
//
//
//    }

    // MARK: - HELPER

    private func setupUnitTestCallbackReceiver(with expectation: XCTestExpectation) {
        unitTestCallbackReceiver = KeyImportSeviceSendObserver(expDidSend: expectation)
        keyImportService.unitTestDelegate = unitTestCallbackReceiver
    }

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
                      expReceivedPrivateKey: expReceivedPrivateKeyCalled)

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
        expReceivedPrivateKey: XCTestExpectation? = nil) {
        observer =
            TestKeyImportServiceObserver(account: account,
                                         expNewInitKeyImportRequestMessageArrived:
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
        do {
            try TestUtil.importKeyByFileName(session, fileName: filenameSec)
            try TestUtil.importKeyByFileName(session, fileName: filenamePub)
            try session.setOwnKey(cdAccount.identity!.pEpIdentity(), fingerprint: fpr)
        } catch {
            XCTFail(error.localizedDescription)
        }

        TestUtil.skipValidation()
        Record.saveAndWait()
        cdAccount.createRequiredFoldersAndWait()
    }

    private func switchTo(device: Device) {
        XCTAssertTrue(PEPUtil.pEpClean())
        setupAccount(device: device)
    }

    private func importPubKey(of device: Device) {
        let filenamePub = keyFileName(device: device) + "pub.asc"
        do {
            try TestUtil.importKeyByFileName(session, fileName: filenamePub)
        } catch {
            XCTFail("importKeyByFileName failed")
        }
    }

    private func trustKey(of device: Device) {
        let pepIdentity = account.user.pEpIdentity()
        pepIdentity.fingerPrint = fingerprint(device: device)
        do {
            try session.trustPersonalKey(pepIdentity)
        } catch {
            XCTFail("trustPersonalKey failed")
        }
    }
}

class TestKeyImportServiceObserver: KeyImportServiceDelegate {
    let account: Account
       let expNewInitKeyImportRequestMessageArrived: XCTestExpectation?
    let expNewHandshakeRequestMessageArrived: XCTestExpectation?
    let expReceivedPrivateKey: XCTestExpectation?

    /// Init observer with what to expect.
    /// If no expectation is passed for a method, we expect that method must not be called.
    init(account: Account,
         expNewInitKeyImportRequestMessageArrived: XCTestExpectation? = nil,
         expNewHandshakeRequestMessageArrived: XCTestExpectation? = nil,
         expReceivedPrivateKey: XCTestExpectation? = nil) {
        self.account = account
        self.expNewInitKeyImportRequestMessageArrived = expNewInitKeyImportRequestMessageArrived
        self.expNewHandshakeRequestMessageArrived = expNewHandshakeRequestMessageArrived
        self.expReceivedPrivateKey = expReceivedPrivateKey
    }

    func newInitKeyImportRequestMessageArrived(forAccount account: Account, fpr: String) {
        if let exp = expNewInitKeyImportRequestMessageArrived {
            XCTAssertEqual(self.account, account)
            exp.fulfill()
        } else {
            XCTFail("method called unexpectedly.")
        }
    }

    func newHandshakeRequestMessageArrived(forAccount account: Account, fpr: String) {
        if let exp = expNewHandshakeRequestMessageArrived {
            XCTAssertEqual(self.account, account)
            exp.fulfill()
        } else {
            XCTFail("method called unexpectedly.")
        }
    }

    func receivedPrivateKey(forAccount account: Account) {
        if let exp = expReceivedPrivateKey {
            XCTAssertEqual(self.account, account)
            exp.fulfill()
        } else {
            XCTFail("method called unexpectedly.")
        }
    }

    func errorOccurred(error: Error) {
        XCTFail("We don't expect errors.")
    }
}

class KeyImportSeviceSendObserver: UnitTestDelegateKeyImportService {
    var expDidSend: XCTestExpectation

    init(expDidSend: XCTestExpectation) {
        self.expDidSend = expDidSend
    }
    func KeyImportService(keyImportService: KeyImportService, didSendKeyimportMessage message: Message) {
        expDidSend.fulfill()
    }
}
