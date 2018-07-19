//
//  ComposeUtilTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 19.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel

//import CoreData

//@testable import MessageModel
@testable import pEpForiOS

class ComposeUtilTest: CoreDataDrivenTestBase {
    var account: Account {
        return cdAccount.account()
    }

    var someone_A: Identity {
        return createForeignIdentity(withId: "A")
    }

    var someone_B: Identity {
        return createForeignIdentity(withId: "B")
    }

    var meCurrentlyUsedAccount: Identity {
        return account.user
    }

    var meSomeUnusedAccount: Identity!

    override func setUp() {
        super.setUp()
        meSomeUnusedAccount = SecretTestData().createWorkingAccount(number: 1).user
    }

    /*
     REPLY

     1) From: Someone A To: Me X CC: ANY
     - Reply Any Mailbox:
     from -> to, to -> from
     result: From: Me X To: Someone A CC: --

     - Reply Sent:
     from -> from, to -> to

     REPLY ALL

     1) From: Someone A To: Me X CC: --
     - ReplyAll Any Mailbox:
     from -> to, to -> from
     result: From: Me X To: Someone A CC: --

     - ReplyAll Sent:
     from -> from, to -> to, cc -> cc

     2) From: Someone A To: Me X, Someone_D CC: Someone_B, Someone_C
     - ReplyAll Any Mailbox:
     from -> msg.parent.account.user, to -> origFrom + (tos - from), CC -> CCs - from
     result: From: Me X To: Someone A, Someone_D CC: Someone_B, Someone_C

     - ReplyAll Sent:
     from -> from, to -> to, cc -> cc
 */

    // MARK: - REPLY
    
    func testReply_inbox_fromSomeoneA_toMe_ccNone_bccNone() {
        let om = createOriginalMessage(inFolderOfType: .inbox,
                                       from: someone_A,
                                       tos: [meCurrentlyUsedAccount],
                                       ccs: [],
                                       bccs: [])
    }

    // MARK: - REPLY ALL

    // MARK: - HELPER

    private func assertRecipients(returnedForOriginalMessage om: Message,
                                  expectedFrom: Identity,
                                  ccs: [Identity],
                                  bccs: [Identity]) {
//        let from = ComposeUtil.initialFrom(composeMode: <#T##ComposeUtil.ComposeMode#>, originalMessage: <#T##Message?#>)

    }

    private func createForeignIdentity(withId id: String) -> Identity {
        let createe = Identity(address: id + "@" + id + ".com",
                               userID: "TEST_ID_" + id,
                               addressBookID: nil,
                               userName: "TEST_USER_NAME_" + id,
                               isMySelf: false)
        return createe
    }

    private func createOriginalMessage(inFolderOfType type: FolderType,
                                       /*of account: Account? = nil,*/
                                       from: Identity,
                                       tos: [Identity],
                                       ccs: [Identity],
                                       bccs: [Identity]) -> Message {
//        let account = account ?? self.account
        guard let parentFolder = account.folder(ofType: type) else {
            fatalError("No folder." +
                "Sorry, I had to crash here. The burn or buy bill would be too negative " +
                "returning an Optional ")
        }
        let createe = Message(uuid: MessageID.generate(), parentFolder: parentFolder)
        createe.from = from
        createe.to = tos
        createe.cc = ccs
        createe.bcc = bccs
        let id = "Test Message - Created by ComposeUtilTest"
        createe.shortMessage = id
        createe.longMessage = id

        return createe
    }

}
