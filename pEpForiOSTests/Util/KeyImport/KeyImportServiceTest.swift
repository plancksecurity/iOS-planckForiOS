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
    var _keyImportService: KeyImportService?
    var keyImportService: KeyImportService { // Only to avoid Optional
        return _keyImportService!
    }
    /// KeyImportService *is* the KeyImportListener. But we want semantical seperation.
    var keyImportListener: KeyImportListenerProtocol {
        return keyImportService
    }
    /// Holds a strong reference. KeyImportService.delegate is weak.
    var observer: TestKeyImportServiceObserver?

        override func setUp() {
        super.setUp()
        cdAccount.createRequiredFoldersAndWait(testCase: self)
        _keyImportService = KeyImportService()
    }

    override func tearDown() {
        _keyImportService = nil
        observer = nil
        super.tearDown()
    }

    func testNewKeyImportMessageArrived_headerSet() {
        assert(keyImportHeaderSet: true,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: false,
               newImportMessageTimedOut: false,
               expectDelegateNewImportMessageArrivedCalled: true,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: true)
    }

    func testNewKeyImportMessageArrived_headerSet_messageTimedOut() {
        assert(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: false,
               newImportMessageTimedOut: true,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    func testNewKeyImportMessageArrived_headerNotSet() {
        assert(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: false,
               newImportMessageTimedOut: false,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    func testNewKeyImportMessageArrived_headerNotSet_messageTimedOut() {
        assert(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: false,
               newImportMessageTimedOut: true,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    func testReceivedPrivateKey_pEpColorGreen_flagReceived() {
        assert(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: true,
               pepColorGreen: true,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: true,
               expectMessageHandledByKeyImportService: true)
    }

    func testReceivedPrivateKey_pEpColorGrey_flagReceived() {
        assert(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: true,
               pepColorGreen: false,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    func testReceivedPrivateKey_pEpColorGreen_noFlagReceived() {
        assert(keyImportHeaderSet: false,
               ownPrivateKeyFlagReceived: false,
               pepColorGreen: true,
               expectDelegateNewImportMessageArrivedCalled: false,
               expectDelegateReceivedPrivateKeyCalled: false,
               expectMessageHandledByKeyImportService: false)
    }

    // MARK: - HELPER

    /// The actual test.
    ///
    /// - Parameters:
    ///   - keyImportHeaderSet: whether or not to set a dummy FPR to "pEp-key-import" header of
    ///the test message
    ///   - ownPrivateKeyFlagReceived:  whether or not the Engine returned
    ///                      PEP_decrypt_flag_own_private_key when decrypting the test message
    ///   - pepColorGreen:  if true, the test message's pepRating represents PEP_color_green.
    ///                     else the test message's pepRating represents PEP_color_none.
    ///   - expectDelegateNewImportMessageArrivedCalled: if true we assert the
    ///                     KeyImportServiceDelegates `newImportMessageArrived`method is called.
    ///                     If false we assert it is *not* called.
    ///   - expectDelegateReceivedPrivateKeyCalled: if true we assert the KeyImportServiceDelegates
    ///                     `receivedPrivateKey`method is called. If false we assert it is *not*
    ///                     called.
    ///   - expectMessageHandledByKeyImportService: whether or not we expect that the test message
    ///                     should be handled by KeyImportListener
    func assert(keyImportHeaderSet: Bool,
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
                               expReceivedPrivateKey: XCTestExpectation? = nil) {
        observer =
            TestKeyImportServiceObserver(expNewImportMessageArrived: expNewImportMessageArrived,
                                         expReceivedPrivateKey: expReceivedPrivateKey)
        keyImportService.delegate = observer
    }

    /// Creates a test message.
    ///
    /// - Parameters:
    ///   - pEpKeyImportHeaderSet: whether or not to set a dummy FPR to "pEp-key-import" header
    ///   - pEpColor:   pEpColor to set PE_rating for.
    ///                 If given pEpColor is not in [green], grey is set
    /// - Returns: test message
    private func createMessage(pEpKeyImportHeaderSet: Bool = false,
                               pEpColor: PEP_color = PEP_color_no_color, timedOut: Bool = false) -> Message {
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

    /// Init observer with what to expect.
    /// If no expectation is passed for a method, we expect that method must not be called.
    init(expNewImportMessageArrived: XCTestExpectation? = nil,
         expReceivedPrivateKey: XCTestExpectation? = nil) {
        self.expNewImportMessageArrived = expNewImportMessageArrived
        self.expReceivedPrivateKey = expReceivedPrivateKey
    }

    func newKeyImportMessageArrived(message: Message) {
        if let exp = expNewImportMessageArrived {
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
}
