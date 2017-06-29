//
//  ImapSyncMachineTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class ImapSyncMachineTests: XCTestCase {
    class ImapSyncMachineObserver: ImapSyncMachineDelegate {
        let cdAccount: CdAccount
        let expFoldersFetched: XCTestExpectation?
        let expMessagesFetched: XCTestExpectation?
        let expMessagesSynced: XCTestExpectation?

        init(cdAccount: CdAccount,
             expFoldersFetched: XCTestExpectation?,
             expMessagesFetched: XCTestExpectation?,
             expMessagesSynced: XCTestExpectation?) {
            self.cdAccount = cdAccount
            self.expFoldersFetched = expFoldersFetched
            self.expMessagesFetched = expMessagesFetched
            self.expMessagesSynced = expMessagesSynced
        }

        func didFetchFolders(machine: ImapSyncMachine) {
            XCTAssertGreaterThan((cdAccount.folders?.array as? [CdFolder] ?? []).count, 0)
            expFoldersFetched?.fulfill()
        }

        func didFetchMessages(machine: ImapSyncMachine) {
            guard
                let cdInbox = CdFolder.by(folderType: .inbox, account: cdAccount)
                else {
                    XCTFail()
                    return
            }
            let msgs = cdInbox.messages?.sortedArray(
                using: [NSSortDescriptor(key: "uid", ascending: true)]) as? [CdMessage] ?? []
            XCTAssertGreaterThan(msgs.count, 0)
            expMessagesFetched?.fulfill()
        }

        func didSyncMessages(machine: ImapSyncMachine) {
            expMessagesSynced?.fulfill()
        }
    }

    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!
    var cdAccountDisfunctional: CdAccount!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        let cdDisfunctionalAccount = TestData().createDisfunctionalCdAccount()
        cdDisfunctionalAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccountDisfunctional = cdDisfunctionalAccount
    }

    override func tearDown() {
        persistentSetup = nil
    }

    func testSimple() {
        let cdAccount = TestData().createWorkingCdAccount()
        Record.saveAndWait()
        guard
            let imapConnectInfo = cdAccount.imapConnectInfo,
            let smtpConnectInfo = cdAccount.smtpConnectInfo
            else {
                XCTFail()
                return
        }

        let machine = ImapSyncMachine(
            imapConnectInfo: imapConnectInfo, smtpConnectInfo: smtpConnectInfo)
        let observer = ImapSyncMachineObserver(
            cdAccount: cdAccount,
            expFoldersFetched: expectation(description: "expFoldersFetched"),
            expMessagesFetched: expectation(description: "expMessagesFetched"),
            expMessagesSynced: expectation(description: "expMessagesSynced"))
        machine.delegate = observer

        machine.start()
        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }
    }

    func syncData(cdAccount: CdAccount) -> (ImapSyncData, SmtpSendData)? {
        guard
            let imapCI = cdAccount.imapConnectInfo,
            let smtpCI = cdAccount.smtpConnectInfo else {
                XCTFail()
                return nil
        }
        return (ImapSyncData(connectInfo: imapCI), SmtpSendData(connectInfo: smtpCI))
    }

    func runSmtpSendService(
        cdAccount theCdAccount: CdAccount, verifyError: @escaping (_ error: Error?) -> ()) {
        guard let (imapSyncData, smtpSendData) = syncData(cdAccount: theCdAccount) else {
            XCTFail()
            return
        }

        let numberOfMailsToSend = TestUtil.createOutgoingMails(cdAccount: theCdAccount)

        let expectationBackgrounded = expectation(description: "expectationBackgrounded")
        let backgrounder = MockBackgrounder(expBackgrounded: expectationBackgrounded)

        let smtpService = SmtpSendService(parentName: #function, backgrounder: backgrounder)
        let expectationSmtpExecuted = expectation(description: "expectationSmtpExecuted")
        smtpService.execute(
        smtpSendData: smtpSendData, imapSyncData: imapSyncData) { error in
            if error == nil {
                XCTAssertEqual(smtpService.successfullySentMessageIDs.count, numberOfMailsToSend)
            } else {
                XCTAssertLessThan(smtpService.successfullySentMessageIDs.count, numberOfMailsToSend)
            }
            verifyError(error)
            expectationSmtpExecuted.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }
    }

    func testSmtpSendServiceOk() {
        runSmtpSendService(cdAccount: cdAccount) { error in
            XCTAssertNil(error)
        }
    }

    func testSmtpSendServiceError() {
        runSmtpSendService(cdAccount: cdAccountDisfunctional) { error in
            XCTAssertNotNil(error)
        }
    }

    func notestInboxSync() {
        let cdAccount = TestData().createWorkingCdAccount()
        Record.saveAndWait()
        guard
            let imapConnectInfo = cdAccount.imapConnectInfo,
            let smtpConnectInfo = cdAccount.smtpConnectInfo
            else {
                XCTFail()
                return
        }
        let _ = expectation(description: "")
        let inboxSync = InboxSync(
            parentName: #function,
            imapConnectInfo: imapConnectInfo, smtpConnectInfo: smtpConnectInfo)
        inboxSync.start()
        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }
    }
}
