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

    func dumpAllAccounts() {
        let cdAccounts = CdAccount.all(in: moc) as? [CdAccount]
        if let accs = cdAccounts {
            for acc in accs {
                print("\(String(describing: acc.identity?.address)) \(String(describing: acc.identity?.userName))")
            }
        }
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
