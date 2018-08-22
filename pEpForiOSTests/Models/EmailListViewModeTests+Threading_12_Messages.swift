//
//  EmailListViewModeTests+Threading_12_Messages.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 22.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class EmailListViewModelTests_Threading_12_Messages: CoreDataDrivenTestBase {
    var account: Account!
    var inbox: Folder!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        account = cdAccount.account()

        inbox = Folder(name: "INBOX", parent: nil, account: account, folderType: .inbox)
        inbox.save()

        let trash = Folder(name: "Trash", parent: nil, account: account, folderType: .trash)
        trash.save()
    }

    // MARK: - Tests

    func testIncoming() {
        let emailListViewModelDelegate = MyEmailListViewModelDelegateIncoming()
        let viewModel = EmailListViewModel(
            emailListViewModelDelegate: emailListViewModelDelegate,
            messageSyncService: MyMessageSyncServiceProtocol(),
            folderToShow: inbox)

        let msg1 = createMessage(number: 1, referencing: [])
        viewModel.didCreate(messageFolder: msg1)
    }

    // MARK: - Helpers

    func createMessage(number: Int, referencing: [Int]) -> Message {
        let aMessage = TestUtil.createMessage(uid: number, inFolder: inbox)
        aMessage.longMessage = "\(number)"
        aMessage.references = referencing.map { return "\($0)" }
        aMessage.save()
        return aMessage
    }

    // MARK: - Delegates

    class MyMessageSyncServiceProtocol: MessageSyncServiceProtocol {
        func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
        }

        func requestFetchOlderMessages(inFolder folder: Folder) {
        }
    }

    class MyEmailListViewModelDelegateIncoming: EmailListViewModelDelegate {
    }
}
