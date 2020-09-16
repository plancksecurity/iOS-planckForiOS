import XCTest

import CoreData

@testable import MessageModel
import PEPObjCAdapterFramework
import PantomimeFramework

class SimpleOperationsTest: PersistentStoreDrivenTestBase {
    func testComp() {
        let f = SyncFoldersFromServerOperation(parentName: #function,
                                               imapConnection: imapConnection)
        XCTAssertTrue(f.comp.contains("SyncFoldersFromServerOperation"))
        XCTAssertTrue(f.comp.contains(#function))
    }

    func testFetchMessagesOperation() {
        XCTAssertNil(CdMessage.all(in: moc))

        TestUtil.syncAndWait(testCase: self)

        XCTAssertGreaterThan(
            CdFolder.countBy(predicate: NSPredicate(value: true), context: moc), 0)
        XCTAssertGreaterThan(
            CdMessage.all(in: moc)?.count ?? 0, 0)

        guard let allMessages = CdMessage.all(in: moc) as? [CdMessage] else {
            XCTFail()
            return
        }

        guard let hostnameData = CWMIMEUtility.hostname() else {
            XCTFail()
            return
        }
        guard let localHostname = hostnameData.toStringWithIANACharset("UTF-8") else {
            XCTFail()
            return
        }

        // Check all messages for validity
        var uuids = [MessageID]()
        for m in allMessages {
            if let uuid = m.messageID {
                uuids.append(uuid)
            } else {
                XCTFail()
            }

            XCTAssertNotNil(m.uid)
            XCTAssertGreaterThan(m.uid, 0)
            XCTAssertNotNil(m.imap)
            XCTAssertNotNil(m.sent)
            XCTAssertNotNil(m.received)

            guard let uuid = m.uuid else {
                XCTFail()
                continue
            }
            XCTAssertFalse(uuid.contains(localHostname))

            XCTAssertTrue(m.isValidMessage())

            guard let cdFolder = m.parent else {
                XCTFail()
                break
            }
            XCTAssertTrue(cdFolder.name?.isInboxFolderName() ?? false)
           let cdMessages = cdFolder.allMessages(context: moc)
            XCTAssertEqual(cdMessages.count, 1)

            XCTAssertNotNil(m.imap)
        }
        TestUtil.checkForExistanceAndUniqueness(uuids: uuids, context: moc)
    }

    func testSyncMessagesFailedOperation() {
        testSyncFoldersFromServerOperation()

        guard
            let folder = CdFolder.by(folderType: .inbox, account: cdAccount),
            let folderName = folder.name else {
                XCTFail()
                return
        }

        let expMailsSynced = expectation(description: "expMailsSynced")

        let op = SyncMessagesInImapFolderOperation(parentName: #function,
                                                   imapConnection: imapConnection,
                                                   folderName: folderName,
                                                   firstUID: 10,
                                                   lastUID: 5)
        op.completionBlock = {
            op.completionBlock = nil
            expMailsSynced.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(op.hasErrors)
        })
    }

    func testSyncFoldersFromServerOperation() {
        let expFoldersFetched = expectation(description: "expFoldersFetched")

        let opLogin = LoginImapOperation(parentName: #function,
                                         imapConnection: imapConnection)
        let op = SyncFoldersFromServerOperation(parentName: #function,
                                                imapConnection: imapConnection)
        op.completionBlock = {
            op.completionBlock = nil
            expFoldersFetched.fulfill()
        }
        op.addDependency(opLogin)

        let bgQueue = OperationQueue()
        bgQueue.addOperation(opLogin)
        bgQueue.addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThanOrEqual(
            CdFolder.countBy(predicate: NSPredicate(value: true), context: moc), 1)

        var options: [String: Any] = ["folderTypeRawValue": FolderType.inbox.rawValue,
                                      "account": cdAccount as Any]
        let inboxFolder = CdFolder.first(attributes: options)
        options["folderTypeRawValue"] = FolderType.sent.rawValue
        XCTAssertNotNil(inboxFolder)
        XCTAssertTrue(inboxFolder?.name?.isInboxFolderName() ?? false)

        let sentFolder = CdFolder.first(attributes: options)
        XCTAssertNotNil(sentFolder)
    }

    func dumpAllAccounts() {
        let cdAccounts = CdAccount.all(in: moc) as? [CdAccount]
        if let accs = cdAccounts {
            for acc in accs {
                print("\(String(describing: acc.identity?.address)) \(String(describing: acc.identity?.userName))")
            }
        }
    }

    func testAppendSentMailsOperation() {
        let imapConnection = ImapConnection(connectInfo: imapConnectInfo)
        let errorContainer = ErrorPropagator()

        let queue = OperationQueue()

        loginIMAP(imapConnection: imapConnection, errorContainer: errorContainer, queue: queue)
        fetchFoldersIMAP(imapConnection: imapConnection, queue: queue)

        guard let from = cdAccount.identity else {
            XCTFail()
            return
        }

        let to = CdIdentity(context: moc)
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        guard let folder = CdFolder.by(folderType: .sent, account: cdAccount) else {
            XCTFail("No folder")
            return
        }

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage(context: moc)
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sent = Date()
            message.addToTo(to)
        }
        moc.saveAndLogErrors()

        if let msgs = CdMessage.all(in: moc) as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.sent)
                XCTAssertEqual(m.uid, Int32(0))
            }
        } else {
            XCTFail()
        }

        appendMailsIMAP(folder: folder,
                        imapConnection: imapConnection,
                        errorContainer: errorContainer,
                        queue: queue)

        XCTAssertEqual((CdMessage.all(in: moc) ?? []).count, 0)
    }

    func testAppendDraftMailsOperation() {
        let imapConnection = ImapConnection(connectInfo: imapConnectInfo)
        let errorContainer = ErrorPropagator()

        let imapLogin = LoginImapOperation(parentName: #function,
                                           errorContainer: errorContainer,
                                           imapConnection: imapConnection)

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
                                                           imapConnection: imapConnection)
        syncFoldersOp.addDependency(imapLogin)
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(imapLogin)
        queue.addOperation(syncFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors)
            XCTAssertFalse(syncFoldersOp.hasErrors)
        })

        let from = CdIdentity(context: moc)
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity(context: moc)
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        guard let folder = CdFolder.by(folderType: .drafts, account: cdAccount) else {
            XCTFail("No folder")
            return
        }

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage(context: moc)
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.addToTo(to)
        }
        moc.saveAndLogErrors()

        if let msgs = CdMessage.all(in: moc) as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.drafts)
                XCTAssertEqual(m.uid, Int32(0))
            }
        } else {
            XCTFail()
        }

        let expDraftsStored = expectation(description: "expDraftsStored")

        let appendOp = AppendMailsToFolderOperation(parentName: #function,
                                                    folder: folder,
                                                    errorContainer: errorContainer,
                                                    imapConnection: imapConnection)
        appendOp.completionBlock = {
            appendOp.completionBlock = nil
            expDraftsStored.fulfill()
        }

        queue.addOperation(appendOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(appendOp.hasErrors)
        })

        XCTAssertEqual((CdMessage.all(in: moc) ?? []).count, 0)
    }

    /**
     It's important to always provide the correct kPepUserID for a local account ID.
     */
    func testSimpleOutgoingMailColor() {
        var (myself, _, _, _, _) = TestUtil.setupSomePEPIdentities()
        myself = mySelf(for: myself)
        XCTAssertNotNil(myself.fingerPrint)
        let testee = rating(for: myself)
        XCTAssertGreaterThanOrEqual(testee.rawValue, PEPRating.reliable.rawValue)
    }

    // MARK: - QualifyServerIsLocalOperation

    func testQualifyServerOperation() {
        XCTAssertEqual(isLocalServer(serverName: "localhost"), true)
        XCTAssertEqual(isLocalServer(serverName: "peptest.ch"), false)
    }

    func isLocalServer(serverName: String) -> Bool? {
        let expServerQualified = expectation(description: "expServerQualified")
        let op = QualifyServerIsLocalOperation(serverName: serverName)
        op.completionBlock = {
            expServerQualified.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(op)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors)
        })
        return op.isLocal
    }
}
