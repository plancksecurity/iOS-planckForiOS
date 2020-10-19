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

class MessageViewModelTests: AccountDrivenTestBase {
    //SUT
    var viewModel: MessageViewModel!

    var workingAccount: Account!
    var folder: Folder!

    struct Defaults {
        struct Inputs {
            static let fromAddress = "miguel@helm.cat"
            static let toAddresses = ["borja@helm.cat", "borja@pep-project.org", "miguel@pep-project.org"]
            static let toAddress = toAddresses[0]
            let fromIdentity = Identity(address: fromAddress)
            let toIdentities = toAddresses.map { Identity(address: $0) }
            let toIdentity = Identity(address: toAddress)
            static let shortMessage = "Hey Borja"
            static let longMessage = "Hey Borja, How is it going?"
            static let longlongMessage = """
                        Hey Borja, How is it going? Are you okay? I was wondering if we
                        could meet sometime this afternoon. I would like to discuss some points
                        about clean architecture
                        """
            static let longMessageFormated = "<h1>Long HTML</h1>"
            static let sentDate = Date(timeIntervalSince1970: 662786656)
            static let numberOfAttachments = 2
        }

        struct Outputs {
            static let toField = "To:borja@helm.cat"
            static let longLongMessage = "Hey Borja, How is it going? Are you okay? I was wondering"
                + " if we could meet sometime this afternoon. I would like to disc"
            static let expectedDateText = "Jan 2, 1991"
            static let expectedNumberOfMessages = 0
        }
    }

    override func setUp() {
        super.setUp()
        let account = TestData().createWorkingAccount()
        folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        folder.session.commit()
    }

    //PRAGMA - MARK: TESTS

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
        let specificWaitTime = UnitTestUtils.waitTime * 10000
        let expectation = XCTestExpectation(description: "body Peek is received")
        viewModel.bodyPeekCompletion = { bodyPeek in
            XCTAssertEqual(bodyPeek, Defaults.Outputs.longLongMessage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: specificWaitTime)
    }

    func testFormattedBody() {
        givenViewModelRepresentsMessageWithFormattedBody()
        let formattedMessage = viewModel.longMessageFormatted
        XCTAssertEqual(formattedMessage, Defaults.Inputs.longMessageFormated)
    }

    func testDateSent() {
        givenViewModelRepresentsMessageWithDate()
        let dateSent = viewModel.dateSent
        XCTAssertEqual(dateSent, Defaults.Inputs.sentDate)
    }

    func testDateSentText() {
        givenViewModelRepresentsMessageWithDate()
        let dateSentText = viewModel.dateText
        XCTAssertEqual(dateSentText, Defaults.Outputs.expectedDateText)
    }

    func testShouldShowAttachmentIcon() {
        givenViewModelRepresentsMessageWithAttachments()
        let shouldShowAttachmentIcon = viewModel.showAttchmentIcon
        XCTAssertTrue(shouldShowAttachmentIcon)
    }

    func testShouldNotShowAttachmentIcon() {
        givenViewModelRepresentsASubjectAndBodyMessage()
        let shouldShowAttachmentIcon = viewModel.showAttchmentIcon
        XCTAssertFalse(shouldShowAttachmentIcon)
    }

    func testProfilePictureIsCalled() {
        givenViewModelHasAProfilePictureComposer()
        viewModel.getProfilePicture { _ in
            //do nothing
        }
        waitForExpectations(timeout: UnitTestUtils.asyncWaitTime)
    }

    //PRAGMA - MARK: BUSINESS

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
        let retrievedMessage = viewModel.message
        XCTAssertEqual(message, retrievedMessage)
    }

    func testFromIdentity() {
        let message = givenThereIsAOneRecipientMessage()
        viewModel = MessageViewModel(with: message)
        guard let identity = message.from else {
            XCTFail("No identity")
            return
        }
        let retrievedIdentity = viewModel.identity
        XCTAssertEqual(identity, retrievedIdentity)
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

    private func givenViewModelRepresentsMessageWithDate() {
        let message = givenThereIsAMessageWithASentDate()
        viewModel = MessageViewModel(with: message)
    }

    private func givenViewModelRepresentsMessageWithFormattedBody() {
        let message = givenThereIsAmessageWithFormattedBody()
        viewModel = MessageViewModel(with: message)
    }

    private func givenViewModelRepresentsMessageWithAttachments() {
        let message = givenThereIsAMessageWithAttachments()
        viewModel = MessageViewModel(with: message)
    }

    private func givenViewModelHasAProfilePictureComposer() {
        viewModel = givenAViewModelRepresentingUnflaggedMessage()
        let profilePictureExpectation = expectation(description: PepProfilePictureComposerSpy.PROFILE_PICTURE_EXPECTATION_DESCRIPTION)
        viewModel.profilePictureComposer = PepProfilePictureComposerSpy(profilePictureExpectation: profilePictureExpectation)
    }

    private func givenAViewModelRepresentingUnflaggedMessage() -> MessageViewModel {
        let message = givenThereIsAOneRecipientMessage()
        return MessageViewModel(with: message)
    }

    //PRAGMA MARK: Messages

    private func givenThereIsAOneRecipientMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder,
                                             from: Defaults.Inputs().fromIdentity,
                                             tos: [Defaults.Inputs().toIdentity])
        message.session.commit()
        return message
    }

    private func givenThereIsAFlaggedAndSeenMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.Inputs().fromIdentity)
        message.imapFlags.seen = true
        message.imapFlags.flagged = true
        message.session.commit()
        return message
    }

    private func givenThereIsAMessageWithSubjectAndBody() -> Message {
        let message = TestUtil.createMessage(inFolder: folder,
                                             from: Defaults.Inputs().fromIdentity,
                                             shortMessage: Defaults.Inputs.shortMessage,
                                             longMessage: Defaults.Inputs.longMessage)
        message.session.commit()
        return message
    }

    private func givenThereIsAMessageWithSubjectAndLongBody() -> Message {
        let message = TestUtil.createMessage(inFolder: folder,
                                             from: Defaults.Inputs().fromIdentity,
                                             shortMessage: Defaults.Inputs.shortMessage,
                                             longMessage: Defaults.Inputs.longlongMessage)
        message.session.commit()
        return message
    }

    private func givenThereIsAmessageWithFormattedBody() -> Message {
        let message = TestUtil.createMessage(inFolder: folder,
                                             from: Defaults.Inputs().fromIdentity,
                                             shortMessage: Defaults.Inputs.shortMessage,
                                             longMessageFormatted: Defaults.Inputs.longMessageFormated)
        message.session.commit()
        return message
    }

    private func givenThereIsAMessageWithASentDate() -> Message {
        let message = TestUtil.createMessage(inFolder: folder,
                                             from: Defaults.Inputs().fromIdentity,
                                             dateSent: Defaults.Inputs.sentDate)
        message.session.commit()
        return message
    }

    private func givenThereIsAMultipleRecipientMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder,
                                             from: Defaults.Inputs().fromIdentity,
                                             tos: Defaults.Inputs().toIdentities)
        message.session.commit()
        return message
    }

    private func givenThereIsAMessageWithAttachments() -> Message {
        let message = TestUtil.createMessage(inFolder: folder,
                                             from: Defaults.Inputs().fromIdentity,
                                             attachments: Defaults.Inputs.numberOfAttachments)
        message.session.commit()
        return message
    }

    //PRAGMA MARK: Mocks

    struct PepProfilePictureComposerSpy: ProfilePictureComposerProtocol {
        static let PROFILE_PICTURE_EXPECTATION_DESCRIPTION = "PROFILE_PICTURE_CALLED"

        let profilePictureExpectation: XCTestExpectation?

        init(profilePictureExpectation: XCTestExpectation? = nil) {
            self.profilePictureExpectation = profilePictureExpectation
        }

        func profilePicture(for identityKey: IdentityImageTool.IdentityKey) -> UIImage? {
            guard let safeProfilePictureExpectation = profilePictureExpectation else {
                XCTFail()
                return nil
            }
            safeProfilePictureExpectation.fulfill()
            return nil
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


