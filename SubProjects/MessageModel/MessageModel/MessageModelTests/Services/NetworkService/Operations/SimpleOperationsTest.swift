import XCTest

import CoreData

@testable import MessageModel
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS
import PantomimeFramework

class SimpleOperationsTest: PersistentStoreDrivenTestBase {
    func testComp() {
        let f = SyncFoldersFromServerOperation(parentName: #function,
                                               imapConnection: imapConnection)
        XCTAssertTrue(f.comp.contains("SyncFoldersFromServerOperation"))
        XCTAssertTrue(f.comp.contains(#function))
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
