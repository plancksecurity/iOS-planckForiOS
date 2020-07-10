//
//  SendMessageCallbackHandlerTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 21.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
import PEPObjCAdapterFramework

//!!!: Tests must use the same project structure as production target. This is clearly not Core Data. Move!
class SendMessageCallbackHandlerTest: PersistentStoreDrivenTestBase {
    let ownAddress = "this_is_my_own@example.com"
    let attachmentData = Data(repeating: 5, count: 100)

    func testError() {
        let handler: PEPSendMessageDelegate = KeySyncService(keySyncStateProvider: TestStateProvider(),
                                                             passphraseProvider: PassphraseProviderMock(),
                                                             usePEPFolderProvider: UsePEPFolderProviderMock())
        let msg = PEPMessageUtil.syncMessage(ownAddress: ownAddress,
                                             attachmentData: attachmentData)
        let result = handler.send(msg)
        XCTAssertNotEqual(result, PEPStatus.OK)
    }

    func testSuccess() {
        let cdIdentity = CdIdentity(context: moc)
        cdIdentity.address = ownAddress
        cdIdentity.userID = "userID00000000"
        cdIdentity.userName = "Bogus H"

        let cdAccount = CdAccount(context: moc)
        cdAccount.identity = cdIdentity

        let cdFolderOut = CdFolder(context: moc)
        cdFolderOut.folderType = .outbox
        cdFolderOut.name = "whatever"

        cdAccount.addToFolders(cdFolderOut)

        moc.saveAndLogErrors()

        let handler: PEPSendMessageDelegate = KeySyncService(keySyncStateProvider: TestStateProvider(),
                                                             passphraseProvider: PassphraseProviderMock(),
                                                             usePEPFolderProvider: UsePEPFolderProviderMock())
        let msg = PEPMessageUtil.syncMessage(ownAddress: ownAddress,
                                             attachmentData: attachmentData)
        let result = handler.send(msg)
        XCTAssertEqual(result, PEPStatus.OK)

        guard let cdMsg = CdMessage.first(in: moc) else {
            XCTFail()
            return
        }

        XCTAssertEqual(cdMsg.messageID, msg.messageID)
        XCTAssertEqual(cdMsg.parent?.folderType, FolderType.outbox)
        XCTAssertEqual(cdMsg.shortMessage, msg.shortMessage)
        XCTAssertEqual(cdMsg.longMessage, msg.longMessage)
    }
}

// MARK: - HELPER

// Dummy class. Soley exists to pass something to KeySyncService.init
class TestStateProvider: KeySyncStateProvider {
    var stateChangeHandler: ((Bool) -> Void)?

    var isKeySyncEnabled: Bool {
        return true
    }
}

class PassphraseProviderMock: PassphraseProviderProtocol {
    func showEnterPassphrase(triggeredWhilePEPSync:Bool = false,
                             completion: @escaping (String?) -> Void) {}

    func showWrongPassphrase(completion: @escaping (String?) -> Void) {}

    func showPassphraseTooLong(completion: @escaping (String?) -> Void) {}
}

class UsePEPFolderProviderMock: UsePEPFolderProviderProtocol {
    var usePepFolder: Bool = false
}
