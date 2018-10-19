//
//  MessageViewModelTests.swift
//  pEpForiOSTests
//
//  Created by Miguel Berrocal Gómez on 10/10/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel


class MessageViewModelTests: CoreDataDrivenTestBase {

    //SUT
    var viewModel: MessageViewModel!

    var workingAccount: Account!
    var folder: Folder!

    struct Defaults {

        struct Inputs {
            static let fromAddress = "miguel@helm.cat"
            static let toAddresses = ["borja@helm.cat", "borja@pep-project.org", "miguel@pep-project.org"]
            static let toAddress = toAddresses[0]
            static let fromIdentity = Identity.create(address: fromAddress)
            static let toIdentities = toAddresses.map { Identity.create(address: $0) }
            static let toIdentity = Identity.create(address: toAddress)
            static let shortMessage = "Hey Borja"
            static let longMessage = "Hey Borja, How is it going?"
            static let longlongMessage = """
                        Hey Borja, How is it going? Are you okay? I was wondering if we
                        could meet sometime this afternoon. I would like to discuss some points
                        about clean architecture
                        """
            static let longMessageFormated = "<h1>Long HTML</h1>"
        }

        struct Outputs {
            static let toField = "To:borja@helm.cat"
            static let longLongMessage = "Hey Borja, How is it going? Are you okay? I was wondering"
                + " if we could meet sometime this afternoon. I would like to disc"
        }
    }

    override func setUp() {
        super.setUp()
        let account = SecretTestData().createWorkingAccount()
        folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        folder.save()
    }

    func testToFieldOneRecipientFormat() {
        givenViewModelRepresentsOneRecipientMessage()
        let toString = viewModel.getTo().string
        XCTAssertEqual(toString, Defaults.Outputs.toField)
    }

    func testToFieldContainsAllRecipients() {
        givenViewModelRepresentsMultipleRecipientMessage()
        let toString = viewModel.getTo().string
        var addressesArePresent = true
        for address in Defaults.Inputs.toAddresses {
            if !toString.contains(find: address) {
                addressesArePresent = false
                break
            }
        }
        XCTAssertTrue(addressesArePresent)
    }

    func testFromField() {
        givenViewModelRepresentsOneRecipientMessage()
        let from = viewModel.from
        XCTAssertEqual(from, Defaults.Inputs.fromAddress)

    }

    func testSubjectField() {
        givenViewModelRepresentsASubjectAndBodyMessage()
        let subject = viewModel.subject
        XCTAssertEqual(subject, Defaults.Inputs.shortMessage)
    }

    func testBodyField() {
        givenViewModelRepresentsASubjectAndBodyMessage()
        let bodyString = viewModel.body.string
        XCTAssertEqual(bodyString, Defaults.Inputs.longMessage)
    }

    func testIsFlagged() {
        givenViewModelRepresentsOneFlaggedAndSeenMessage()
        let isFlagged = viewModel.isFlagged
        XCTAssertTrue(isFlagged)
    }

    func testIsUnflagged() {
        givenViewModelRepresentsUnflaggedMessage()
        let isUnflagged = !viewModel.isFlagged
        XCTAssertTrue(isUnflagged)
    }

    func testIsSeen() {
        givenViewModelRepresentsOneFlaggedAndSeenMessage()
        let isSeen = viewModel.isSeen
        XCTAssertTrue(isSeen)
    }

    func testIsUnseen() {
        givenViewModelRepresentsUnflaggedMessage()
        let isUnseen = !viewModel.isSeen
        XCTAssertTrue(isUnseen)
    }

    func testShortBodyPeek() {
        givenViewModelRepresentsASubjectAndBodyMessage()
        let expectation = XCTestExpectation(description: "body Peek is received")
        viewModel.bodyPeekCompletion = { bodyPeek in
            XCTAssertEqual(bodyPeek, Defaults.Inputs.longMessage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: UnitTestUtils.waitTime)
    }

    func testLongBodyPeek() {
        givenViewModelRepresentsASubjectAndLongBodyMessage()
        let specificWaitTime = UnitTestUtils.waitTime * 5
        let expectation = XCTestExpectation(description: "body Peek is received")
        viewModel.bodyPeekCompletion = { bodyPeek in
            XCTAssertEqual(bodyPeek, Defaults.Outputs.longLongMessage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: specificWaitTime)
    }

    func testSecurityBadgeIsAddedToQueue() {
        givenViewModelHasAnAddingExpectationOperationQueue()
        viewModel.getSecurityBadge { _ in
            //do nothing
        }
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testBodyPeekIsAddedToQueue() {
        givenViewModelHasAnInitialAddingExpectationOperationQueue()
        viewModel.bodyPeekCompletion = { _ in
            //do nothing
        }
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testQueueCancelledWhenStoppingUpdates() {
        givenViewModelHasACancellingExpectationOperationQueue()
        viewModel.unsubscribeForUpdates()
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testProfilePictureIsCalled() {
        givenViewModelHasAProfilePictureComposer()
        viewModel.getProfilePicture { _ in
            //do nothing
        }
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testSecurityBadgeIsCalled() {
        givenViewModelHasASecurityBadgePictureComposer()
        viewModel.getSecurityBadge { _ in
            //do nothing
        }
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    //PRAGMA - MARK: BUSINESS
    //business public methods (should be private in the future or moved to another component,
    //some refactor would be needed)

    func testFlagsDiffer() {
        givenViewModelRepresentsOneFlaggedAndSeenMessage()
        let otherViewModel = givenAViewModelRepresentingUnflaggedMessage()
        let flagsDiffer = viewModel.flagsDiffer(from: otherViewModel)
        XCTAssertTrue(flagsDiffer)
    }

    func testFlagsAreTheSame() {
        let message = givenThereIsAFlaggedAndSeenMessage()
        viewModel = MessageViewModel(with: message)
        let otherViewModel = MessageViewModel(with: message)
        let flagsAreTheSame = !viewModel.flagsDiffer(from: otherViewModel)
        XCTAssertTrue(flagsAreTheSame)
    }

    func testMessageIsTheSame() {
        let message = givenThereIsAOneRecipientMessage()
        viewModel = MessageViewModel(with: message)
        let retrievedMessage = viewModel.message()!
        XCTAssertEqual(message, retrievedMessage)
    }

    //PRAGMA - MARK: GIVEN

    //PRAGMA MARK: ViewModels

    private func givenViewModelRepresentsUnflaggedMessage() {
        viewModel = givenAViewModelRepresentingUnflaggedMessage()
    }

    private func givenViewModelRepresentsOneFlaggedAndSeenMessage() {
        let message = givenThereIsAFlaggedAndSeenMessage()
        viewModel = MessageViewModel(with: message)
    }

    private func givenViewModelRepresentsOneRecipientMessage() {
        let message = givenThereIsAOneRecipientMessage()
        viewModel = MessageViewModel(with: message)
    }

    private func givenViewModelRepresentsMultipleRecipientMessage() {
        let message = givenThereIsAMultipleRecipientMessage()
        viewModel = MessageViewModel(with: message)
    }

    private func givenViewModelRepresentsASubjectAndBodyMessage() {
        let message = givenThereIsAMessageWithSubjectAndBody()
        viewModel = MessageViewModel(with: message)
    }

    private func givenViewModelRepresentsASubjectAndLongBodyMessage() {
        let message = givenThereIsAMessageWithSubjectAndLongBody()
        viewModel = MessageViewModel(with: message)
    }

    private func givenViewModelHasAProfilePictureComposer() {
        viewModel = givenAViewModelRepresentingUnflaggedMessage()
        let profilePictureExpectation = expectation(description: PepProfilePictureComposerSpy.PROFILE_PICTURE_EXPECTATION_DESCRIPTION)
        viewModel.profilePictureComposer = PepProfilePictureComposerSpy(profilePictureExpectation: profilePictureExpectation)
    }

    private func givenViewModelHasASecurityBadgePictureComposer() {
        viewModel = givenAViewModelRepresentingUnflaggedMessage()
        let securityBadgeExpectation = expectation(description: PepProfilePictureComposerSpy.SECURITY_BADGE_EXPECTATION_DESCRIPTION)
        viewModel.profilePictureComposer = PepProfilePictureComposerSpy(securityBadgeExpectation: securityBadgeExpectation)
    }

    private func givenViewModelHasAnInitialAddingExpectationOperationQueue() {
        let addOperationExpectation = expectation(description: OperationQueueSpy.ADD_OPERATION_EXPECTATION_DESCRIPTION)
        let operationQueue = OperationQueueSpy(addOperationExpectation: addOperationExpectation)
        viewModel = givenAViewModelWith(operationQueue: operationQueue)
    }


    private func givenViewModelHasACancellingExpectationOperationQueue() {
        viewModel = givenAViewModelRepresentingUnflaggedMessage()
        let cancelAllExpectation = expectation(description: OperationQueueSpy.CANCEL_ALL_EXPECTATION_DESCRIPTION)
        let operationQueue = OperationQueueSpy(cancelAllExpectation: cancelAllExpectation)
        viewModel.queue = operationQueue
    }

    private func givenViewModelHasAnAddingExpectationOperationQueue() {
        viewModel = givenAViewModelRepresentingUnflaggedMessage()
        let addOperationExpectation = expectation(description: OperationQueueSpy.ADD_OPERATION_EXPECTATION_DESCRIPTION)
        let operationQueue = OperationQueueSpy(addOperationExpectation: addOperationExpectation)
        viewModel.queue = operationQueue
    }

    private func givenAViewModelRepresentingUnflaggedMessage() -> MessageViewModel {
        let message = givenThereIsAOneRecipientMessage()
        return MessageViewModel(with: message)
    }

    private func givenAViewModelWith(operationQueue: OperationQueue) -> MessageViewModel {
        let message = givenThereIsAOneRecipientMessage()
        return MessageViewModel(with: message, operationQueue: operationQueue)
    }


    //PRAGMA MARK: Messages

    private func givenThereIsAOneRecipientMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.Inputs.fromIdentity, tos: [Defaults.Inputs.toIdentity])
        message.save()
        return message
    }

    private func givenThereIsAFlaggedAndSeenMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.Inputs.fromIdentity)
        message.imapFlags?.seen = true
        message.imapFlags?.flagged = true
        message.save()
        return message
    }

    private func givenThereIsAMessageWithSubjectAndBody() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.Inputs.fromIdentity, shortMessage: Defaults.Inputs.shortMessage, longMessage: Defaults.Inputs.longMessage)
        message.save()
        return message
    }

    private func givenThereIsAMessageWithSubjectAndLongBody() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.Inputs.fromIdentity, shortMessage: Defaults.Inputs.shortMessage, longMessage: Defaults.Inputs.longlongMessage)
        message.save()
        return message
    }


    private func givenThereIsAMultipleRecipientMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.Inputs.fromIdentity, tos: Defaults.Inputs.toIdentities)
        message.save()
        return message
    }

    //PRAGMA MARK: Mocks

    struct PepProfilePictureComposerSpy: ProfilePictureComposer {

        static let PROFILE_PICTURE_EXPECTATION_DESCRIPTION = "PROFILE_PICTURE_CALLED"
        static let SECURITY_BADGE_EXPECTATION_DESCRIPTION = "SECURITY_BADGE_CALLED"

        let profilePictureExpectation: XCTestExpectation?
        let securityBadgeExpectation: XCTestExpectation?

        init(profilePictureExpectation: XCTestExpectation? = nil, securityBadgeExpectation: XCTestExpectation? = nil) {
            self.profilePictureExpectation = profilePictureExpectation
            self.securityBadgeExpectation = securityBadgeExpectation
        }


        func profilePicture(for identity: Identity, completion: @escaping (UIImage?) -> ()) {
            guard let safeProfilePictureExpectation = profilePictureExpectation else {
                XCTFail()
                return
            }
            safeProfilePictureExpectation.fulfill()
        }

        func securityBadge(for message: Message, completion: @escaping (UIImage?) -> ()) {
            guard let safeSecurityBadgeExpectation = securityBadgeExpectation else {
                XCTFail()
                return
            }
            safeSecurityBadgeExpectation.fulfill()
        }

    }

    class OperationQueueSpy: OperationQueue {

        static let CANCEL_ALL_EXPECTATION_DESCRIPTION = "CANCELL_ALL_CALLED"
        static let ADD_OPERATION_EXPECTATION_DESCRIPTION = "ADD_OPERATION_CALLED"

        let cancelAllExpectation: XCTestExpectation?
        let addOperationExpectation: XCTestExpectation?


        init(cancelAllExpectation: XCTestExpectation? = nil, addOperationExpectation: XCTestExpectation? = nil) {
            self.cancelAllExpectation = cancelAllExpectation
            self.addOperationExpectation = addOperationExpectation
        }

        override func cancelAllOperations() {
            guard let safeCancelAllExpectation = cancelAllExpectation else {
                XCTFail()
                return
            }
            safeCancelAllExpectation.fulfill()
        }

        override func addOperation(_ op: Operation) {
            guard let safeAddOperationExpectation = addOperationExpectation else {
                XCTFail()
                return
            }
            safeAddOperationExpectation.fulfill()
        }
    }
}


