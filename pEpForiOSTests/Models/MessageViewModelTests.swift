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

    struct Constants {
        static let fromAddress = "miguel@helm.cat"
        static let toAddress = "borja@helm.cat"
    }
    
    override func setUp() {
        super.setUp()
        let message = givenThereIsAOneRecipientMessage()
        viewModel = MessageViewModel(with: message)
    }

    func testToFieldOneRecipient() {
        let toString = "To:" + Constants.toAddress
        XCTAssert(viewModel.getTo().string == toString)
    }

    private func givenThereIsAOneRecipientMessage() -> Message {
        let account = SecretTestData().createWorkingAccount()
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        folder.save()
        let toIdentity = Identity.create(address: Constants.toAddress)
        let fromIdentity = Identity.create(address: Constants.fromAddress)
        toIdentity.save()
        fromIdentity.save()
        let message = try! TestUtil.createOutgoingMails(account: account, fromIdentity: fromIdentity, toIdentity: toIdentity, testCase: self, numberOfMails: 1, withAttachments: true)[0]
        message.save()
        return message
    }

}

enum FakeError: Error {
    case noFolder
}
