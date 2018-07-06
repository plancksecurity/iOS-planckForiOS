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

    /// KeyImportService *is* the KeyImportListener. But we want semantical seperation.
    var keyImportListener: KeyImportListenerProtocol {
        return keyImportService
    }
    /// Holds a strong reference. KeyImportService.delegate is weak.
    var observer: TestKeyImportServiceObserver?

    override func setUp() {
        super.setUp()
        cdAccount.createRequiredFoldersAndWait(testCase: self)
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

    // MARK: newKeyImportMessageArrived

    func testNewKeyImportMessageArrived_headerSet() {
        assertHandleKeyImport(keyImportHeaderSet: true,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: false,
               newImportMessageTimedOut: false,
               expectDelegateNewImportMessageArrivedCalled: true,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: true)
    }

    func testNewKeyImportMessageArrived_headerSet_messageTimedOut() {
        assertHandleKeyImport(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: false,
               newImportMessageTimedOut: true,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    func testNewKeyImportMessageArrived_headerNotSet() {
        assertHandleKeyImport(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: false,
               newImportMessageTimedOut: false,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    func testNewKeyImportMessageArrived_headerNotSet_messageTimedOut() {
        assertHandleKeyImport(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: false,
               newImportMessageTimedOut: true,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    // MARK: receivedPrivateKey

    func testReceivedPrivateKey_pEpColorGreen_flagReceived() {
        assertHandleKeyImport(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: true,
               pepColorGreen: true,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: true,
               expectMessageHandledByKeyImportService: true)
    }

    func testReceivedPrivateKey_pEpColorGrey_flagReceived() {
        assertHandleKeyImport(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: true,
               pepColorGreen: false,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    func testReceivedPrivateKey_pEpColorGreen_noFlagReceived() {
        assertHandleKeyImport(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: true,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    // MARK: - KeyImportServiceProtocol

    // MARK: sendInitKeyImportMessage

    func testSendInitKeyImportMessage() {

        // Setup
        let expNewImportMessageArrivedCalled =
            expectation(description: "expNewImportMessageArrivedCalled")
//        let expectedColor = PEP_color_no_color
//        setupObserver(expNewImportMessageArrived: expNewImportMessageArrivedCalled,
//                      expectedImportMessagePepColor: expectedColor)
//        // Send message
//        keyImportService.sendInitKeyImportMessage(forAccount: account)
//
//        sleep(3)
//
//        // Does it arrive and trigger?
        TestUtil.syncAndWait()
//        expNewImportMessageArrivedCalled.fulfill()
//        waitForExpectations(timeout: TestUtil.waitTime) { (error) in
//            XCTAssertNil(error)
//        }
    }

    // MARK: - HELPER

    //IOS-1028: move?

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
    ///   - expectDelegateNewImportMessageArrivedCalled: if true we assert the
    ///                     KeyImportServiceDelegates `newImportMessageArrived`method is called.
    ///                     If false we assert it is *not* called.
    ///   - expectDelegateReceivedPrivateKeyCalled: if true we assert the KeyImportServiceDelegates
    ///                     `receivedPrivateKey`method is called. If false we assert it is *not*
    ///                     called.
    ///   - expectMessageHandledByKeyImportService: whether or not we expect that the test message
    ///                     should be handled by KeyImportListener
    func assertHandleKeyImport(keyImportHeaderSet: Bool,
                ownPrivateKeyFlagReceived: Bool,
                pepColorGreen: Bool,
                newImportMessageTimedOut: Bool = false,
                expectDelegateNewImportMessageArrivedCalled: Bool,
                expectDelegateReceivedPrivateKeyCalled: Bool,
                expectMessageHandledByKeyImportService: Bool) {
        // Setup
        let expNewImportMessageArrivedCalled = expectDelegateNewImportMessageArrivedCalled ?
            expectation(description: "expNewImportMessageArrivedCalled") : nil

        let expReceivedPrivateKeyCalled = expectDelegateReceivedPrivateKeyCalled ?
            expectation(description: "expReceivedPrivateKeyCalled") : nil

        let flagReturnedByEngine =
            ownPrivateKeyFlagReceived ? PEP_decrypt_flag_own_private_key : PEP_decrypt_flag_none

        let pepColor = pepColorGreen ? PEP_color_green : PEP_color_no_color

        setupObserver(expNewImportMessageArrived: expNewImportMessageArrivedCalled,
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

        let thereAreExpectationsToWaitFor =
            expNewImportMessageArrivedCalled != nil || expReceivedPrivateKeyCalled != nil
        if  thereAreExpectationsToWaitFor {
            waitForExpectations(timeout: TestUtil.waitTime) { (error) in
                XCTAssertNil(error)
            }
        }
    }

    private func setupObserver(expNewImportMessageArrived: XCTestExpectation? = nil,
                               expReceivedPrivateKey: XCTestExpectation? = nil,
                               expectedImportMessagePepColor: PEP_color? = nil) {
        observer =
            TestKeyImportServiceObserver(expNewImportMessageArrived: expNewImportMessageArrived,
                                         expReceivedPrivateKey: expReceivedPrivateKey,
                                         expectedImportMessagePepColor:
                expectedImportMessagePepColor)
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
        }
        return msg
    }
}

class TestKeyImportServiceObserver: KeyImportServiceDelegate {
    let expNewImportMessageArrived: XCTestExpectation?
    let expReceivedPrivateKey: XCTestExpectation?
    let expectedImportMessagePepColor: PEP_color?

    /// Init observer with what to expect.
    /// If no expectation is passed for a method, we expect that method must not be called.
    init(expNewImportMessageArrived: XCTestExpectation? = nil,
         expReceivedPrivateKey: XCTestExpectation? = nil,
         expectedImportMessagePepColor: PEP_color? = nil) {
        self.expNewImportMessageArrived = expNewImportMessageArrived
        self.expReceivedPrivateKey = expReceivedPrivateKey
        self.expectedImportMessagePepColor = expectedImportMessagePepColor
    }

    func newKeyImportMessageArrived(message: Message) {
        if let exp = expNewImportMessageArrived {
            if let expectedColor = expectedImportMessagePepColor {
                XCTAssertEqual(message.pEpColor(), expectedColor)
            }
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
