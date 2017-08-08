//
//  LoginViewModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class LoginViewModelTests: XCTestCase {
    class TestMessageSyncService: MessageSyncServiceProtocol {
        weak var errorDelegate: MessageSyncServiceErrorDelegate?
        weak var sentDelegate: MessageSyncServiceSentDelegate?
        weak var syncDelegate: MessageSyncServiceSyncDelegate?
        weak var stateDelegate: MessageSyncServiceStateDelegate?
        weak var flagsUploadDelegate: MessageSyncFlagsUploadDelegate?

        func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
            XCTFail("unexpected call to \(#function)")
        }

        func requestDraft(message: Message) {
            XCTFail("unexpected call to \(#function)")
        }

        func requestSend(message: Message) {
            XCTFail("unexpected call to \(#function)")
        }

        func requestFlagChange(message: Message) {
            XCTFail("unexpected call to \(#function)")
        }

        func requestMessageSync(folder: Folder) {
            XCTFail("unexpected call to \(#function)")
        }

        func start(account: Account) {
            XCTFail("unexpected call to \(#function)")
        }

        func cancel(account: Account) {
            XCTFail("unexpected call to \(#function)")
        }
    }

    func testBasic() {
        let td = TestData()
        let account = td.createWorkingAccountSettings()
        let ms = TestMessageSyncService()
        let vm = LoginViewModel(messageSyncService: ms)
        guard let passw = account.password else {
            XCTFail("Expect password for account")
            return
        }
        vm.login(account: account.idAddress, password: passw, login: nil, username: nil) {
            error in
            XCTAssertNil(error)
        }
    }
}
