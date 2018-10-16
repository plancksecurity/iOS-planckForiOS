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
    var viewModel: MessageViewModel!

    var workingAccount: Account!
    var folder: Folder!

    struct Defaults {
        static let fromAddress = "miguel@helm.cat"
        static let toAddresses = ["borja@helm.cat", "borja@pep-project.org", "miguel@pep-project.org"]
        static let toAddress = toAddresses[0]
        static let fromIdentity = Identity.create(address: fromAddress)
        static let toIdentities = toAddresses.map { Identity.create(address: $0) }
        static let toIdentity = Identity.create(address: toAddress)
        static let shortMessage = "Hey Borja"
        static let longMessage = "Hey Borja, How is it going?"
        static let longMessageFormated = "<h1>Long HTML</h1>"
    }

    override func setUp() {
        super.setUp()
        let account = SecretTestData().createWorkingAccount()
        folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        folder.save()
    }

    func testToFieldOneRecipientFormat() {
        givenViewModelRepresentsOneRecipientMessage()
        let toString = "To:" + Defaults.toAddress
        XCTAssert(viewModel.getTo().string == toString)
    }

    func testToFieldContainsAllRecipients() {
        givenViewModelRepresentsMultipleRecipientMessage()
        let toString = viewModel.getTo().string
        var addressesArePresent = true
        for address in Defaults.toAddresses {
            if !toString.contains(find: address) {
                addressesArePresent = false
                break
            }
        }
        XCTAssert(addressesArePresent, "All Addresses should be contained in the to field")
    }

    func testFromField() {
        givenViewModelRepresentsOneRecipientMessage()
        XCTAssert(viewModel.from == Defaults.fromAddress)
    }

    func testSubjectField() {
        givenViewModelRepresentsASubjectAndBodyMessage()
        XCTAssert(viewModel.subject == Defaults.shortMessage)
    }

    func testBodyField() {
        givenViewModelRepresentsASubjectAndBodyMessage()
        XCTAssert(viewModel.body.string == Defaults.longMessage)
    }

    func testIsFlagged() {
        givenViewModelRepresentOneFlaggedAndSeenMessage()
        XCTAssert(viewModel.isFlagged)
    }

    func testIsSeen() {
        givenViewModelRepresentOneFlaggedAndSeenMessage()
        XCTAssert(viewModel.isSeen)
    }

    private func givenViewModelRepresentOneFlaggedAndSeenMessage() {
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

    private func givenThereIsAOneRecipientMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.fromIdentity, tos: [Defaults.toIdentity])
        message.save()
        return message
    }

    private func givenThereIsAFlaggedAndSeenMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.fromIdentity)
        message.imapFlags?.seen = true
        message.imapFlags?.flagged = true
        message.save()
        return message
    }

    private func givenThereIsAMessageWithSubjectAndBody() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.fromIdentity, shortMessage: Defaults.shortMessage, longMessage: Defaults.longMessage)
        message.imapFlags?.seen = true
        message.imapFlags?.flagged = true
        message.save()
        return message
    }

    private func givenThereIsAMultipleRecipientMessage() -> Message {
        let message = TestUtil.createMessage(inFolder: folder, from: Defaults.fromIdentity, tos: Defaults.toIdentities)
        message.save()
        return message
    }

}
