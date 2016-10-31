//
//  MessageModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel

class MessageModelTests: XCTestCase {
    /**
     Invoke completion block without errors for all actions.
     */
    class TestSendLayer: SendLayerProtocol {
        func verify(account: CdAccount, completionBlock: SendLayerCompletionBlock?) {
            completionBlock?(nil)
        }

        func send(message: CdMessage, completionBlock: SendLayerCompletionBlock?) {
            completionBlock?(nil)
        }

        func saveDraft(message: CdMessage, completionBlock: SendLayerCompletionBlock?) {
            completionBlock?(nil)
        }

        func syncFlagsToServer(folder: CdFolder, completionBlock: SendLayerCompletionBlock?) {
            completionBlock?(nil)
        }

        func create(folderType: FolderType, account: CdAccount,
                    completionBlock: SendLayerCompletionBlock?) {
            completionBlock?(nil)
        }

        func delete(folder: CdFolder, completionBlock: SendLayerCompletionBlock?) {
            completionBlock?(nil)
        }

        func delete(message: CdMessage, completionBlock: SendLayerCompletionBlock?) {
            completionBlock?(nil)
        }
    }

    class TestAccountDelegate: AccountDelegate {
        var expVerifyCalled: XCTestExpectation?
        var error: MessageModelError?

        func didVerify(account: Account, error: MessageModelError?) {
            self.error = error
            expVerifyCalled?.fulfill()
        }
    }

    override func setUp() {
        super.setUp()
        let _ = PersistentSetup.init()
    }
    
    func testAccountSave() {
        CdAccount.sendLayer = TestSendLayer()

        // setup AccountDelegate
        let callBack = TestAccountDelegate()
        callBack.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = callBack

        // create account
        let id = Identity.create(address: "user1@example.com", userName: "User 1",
                                 userID: "user1")
        let server = Server.create(serverType: .imap, port: 993, address: "noserverhere",
                                   transport: .tls)
        let cred = ServerCredentials.create(userName: id.userID!, servers: [server])
        let acc = Account.create(identity: id, credentials: [cred])
        acc.save()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(callBack.error)
        })
    }
}
