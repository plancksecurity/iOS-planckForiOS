//
//  QueryResultsControllerTest.swift
//  MessageModelTests
//
//  Created by Andreas Buff on 20.02.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData
@testable import MessageModel

class QueryResultsControllerTest: PersistentStoreDrivenTestBase {
    var sortDescriptor = NSSortDescriptor(key: "sent", ascending: true)

    // MARK: - results

    func testNoResults() {
        let expectedResults = [CdMessage]()
        assertQueryResults(areEqualTo: expectedResults)
    }

    func testOneResultSuccess() {
        moc.performAndWait {
            let msg = TestUtil.createMessage(moc: moc)
            do {
                try moc.save()
            } catch {
                XCTFail()
            }
            let expectedResults = [msg]
            assertQueryResults(areEqualTo: expectedResults)
        }
    }

    func testUnsavedMsgFormOtherContextNotIncluded() {
        moc.performAndWait {
            let msg = TestUtil.createMessage(moc: moc)
            do {
                try moc.save()
            } catch {
                XCTFail()
            }
            // Create msg without saving the context. Must not show up in results.
            let otherContext = Stack.shared.newPrivateConcurrentContext
            otherContext.performAndWait {
                let _ = TestUtil.createMessage(moc: otherContext)
            }
            let expectedResults = [msg]
            assertQueryResults(areEqualTo: expectedResults,
                               mocToFetchWith: moc)
        }
    }

    // DID INSERT

    func testDidInsertCalled_first() {
        moc.performAndWait {
            let expControllerWillChangeResultsCalled =
                expectation(description: "expControllerWillChangeResultsCalled")

            let expDidChangeObcAtIndexPathCalled =
                expectation(description: "expDidChangeObcAtIndexPathCalled")

            let expControllerDidChangeResultsCalled =
                expectation(description: "expControllerDidChangeResultsCalled")

            let expectedIndexPath: IndexPath? = nil

            let expectedChangeType = NSFetchedResultsChangeType.insert
            let expectedNewIndexPath: IndexPath? = IndexPath(row: 0, section: 0)

            let delegate =
                TestDelegate(expControllerWillChangeResultsCalled: expControllerWillChangeResultsCalled,
                             expDidChangeObcAtIndexPathCalled: expDidChangeObcAtIndexPathCalled,
                             expectedIndexPath: expectedIndexPath,
                             expectedChangeType: expectedChangeType,
                             expectedNewIndexPath: expectedNewIndexPath,
                             expControllerDidChangeResultsCalled: expControllerDidChangeResultsCalled)

            let testee = QueryResultsController<CdMessage>(predicate: nil,
                                                           context: moc,
                                                           cacheName: nil,
                                                           sortDescriptors: [sortDescriptor],
                                                           delegate: delegate)
            do {
                // Start listening ...
                try testee.startMonitoring()
                // ... no results so far.
                XCTAssertEqual(try? testee.getResults().count, 0)
                // Insert a message. Is the delegate called?
                let _ = TestUtil.createMessage(moc: moc)
                XCTAssertNoThrow(try moc.save())
            } catch {
                XCTFail("throws unexpectedly")
            }

            waitForExpectations(timeout: TestUtil.waitTime) { error in
                guard error == nil else {
                    XCTFail()
                    return
                }
            }
        }
    }

    func testDidInsertCalled_last() {
        moc.performAndWait {
            // One message exists.
            let _ = TestUtil.createMessage(moc: moc)
            do {
                try moc.save()
            } catch {
                XCTFail()
            }

            let expControllerWillChangeResultsCalled =
                expectation(description: "expControllerWillChangeResultsCalled")

            let expDidChangeObcAtIndexPathCalled =
                expectation(description: "expDidChangeObcAtIndexPathCalled")

            let expControllerDidChangeResultsCalled =
                expectation(description: "expControllerDidChangeResultsCalled")

            let expectedIndexPath: IndexPath? = nil

            let expectedChangeType = NSFetchedResultsChangeType.insert
            let expectedNewIndexPath: IndexPath? = IndexPath(row: 1, section: 0)

            let delegate =
                TestDelegate(expControllerWillChangeResultsCalled: expControllerWillChangeResultsCalled,
                             expDidChangeObcAtIndexPathCalled: expDidChangeObcAtIndexPathCalled,
                             expectedIndexPath: expectedIndexPath,
                             expectedChangeType: expectedChangeType,
                             expectedNewIndexPath: expectedNewIndexPath,
                             expControllerDidChangeResultsCalled: expControllerDidChangeResultsCalled)

            let testee = QueryResultsController<CdMessage>(predicate: nil,
                                                           context: moc,
                                                           cacheName: nil,
                                                           sortDescriptors: [sortDescriptor],
                                                           delegate: delegate)
            do {
                // Start listening ...
                try testee.startMonitoring()
                // Insert a second message. Is the delegate called?
                let _ = TestUtil.createMessage(moc: moc)
                XCTAssertNoThrow(try moc.save())
            } catch {
                XCTFail("throws unexpectedly")
            }

            waitForExpectations(timeout: TestUtil.waitTime) { error in
                guard error == nil else {
                    XCTFail()
                    return
                }
            }
        }
    }

    // DID DELETE

    func testDidDeleteCalled() {
        moc.performAndWait {
            // Create 3 messages
            let msg1 = TestUtil.createMessage(moc: moc)
            let msg2 = TestUtil.createMessage(moc: moc)
            let msg3 = TestUtil.createMessage(moc: moc)
            let expectedResultsBefore = [msg1, msg2, msg3]
            do {
                try moc.save()
            } catch {
                XCTFail()
            }

            let deletee = msg2
            guard let idxDeletee = expectedResultsBefore.firstIndex(of: deletee) else {
                XCTFail("invalid state")
                return
            }
            var expectedResultsAfterDeleting = expectedResultsBefore
            expectedResultsAfterDeleting.remove(at: idxDeletee)

            let expControllerWillChangeResultsCalled =
                expectation(description: "expControllerWillChangeResultsCalled")

            let expDidChangeObcAtIndexPathCalled =
                expectation(description: "expDidChangeObcAtIndexPathCalled")

            let expControllerDidChangeResultsCalled =
                expectation(description: "expControllerDidChangeResultsCalled")


            let expectedIndexPath: IndexPath? = IndexPath(row: idxDeletee, section: 0)


            let expectedChangeType = NSFetchedResultsChangeType.delete
            let expectedNewIndexPath: IndexPath? = nil

            let delegate =
                TestDelegate(expControllerWillChangeResultsCalled: expControllerWillChangeResultsCalled,
                             expDidChangeObcAtIndexPathCalled: expDidChangeObcAtIndexPathCalled,
                             expectedIndexPath: expectedIndexPath,
                             expectedChangeType: expectedChangeType,
                             expectedNewIndexPath: expectedNewIndexPath,
                             expControllerDidChangeResultsCalled: expControllerDidChangeResultsCalled)

            let testee = QueryResultsController<CdMessage>(predicate: nil,
                                                           context: moc,
                                                           cacheName: nil,
                                                           sortDescriptors: [sortDescriptor],
                                                           delegate: delegate)
            do {
                // Start listening ...
                try testee.startMonitoring()
                XCTAssertEqual(try? testee.getResults().count, expectedResultsBefore.count)
                // Delete a message. Is the delegate called?
                moc.delete(deletee)
                XCTAssertNoThrow(try moc.save())
            } catch {
                XCTFail("throws unexpectedly")
            }

            waitForExpectations(timeout: TestUtil.waitTime) { error in
                guard error == nil else {
                    XCTFail()
                    return
                }
            }

            do {
                let resultsAfterDeleting = try testee.getResults()
                XCTAssertEqual(resultsAfterDeleting.count, expectedResultsAfterDeleting.count)
                XCTAssertFalse(resultsAfterDeleting.contains(deletee))
            } catch{
                XCTFail("throws unexpectedly")
            }
        }
    }

    // DID UPDATE

    func testDidUpdateCalled() {
        moc.performAndWait {
            // Create 3 messages
            let msg1 = TestUtil.createMessage(moc: moc)
            let msg2 = TestUtil.createMessage(moc: moc)
            let msg3 = TestUtil.createMessage(moc: moc)
            let expectedResultsBefore = [msg1, msg2, msg3]
            do {
                try moc.save()
            } catch {
                XCTFail()
            }
            let modifyee = msg2
            guard let idxModifyee = expectedResultsBefore.firstIndex(of: modifyee) else {
                XCTFail("invalid state")
                return
            }
            let expectedResultsAfter = expectedResultsBefore

            let expControllerWillChangeResultsCalled =
                expectation(description: "expControllerWillChangeResultsCalled")

            let expDidChangeObcAtIndexPathCalled =
                expectation(description: "expDidChangeObcAtIndexPathCalled")

            let expControllerDidChangeResultsCalled =
                expectation(description: "expControllerDidChangeResultsCalled")

            let expectedIndexPath: IndexPath? = IndexPath(row: idxModifyee, section: 0)

            let expectedChangeType = NSFetchedResultsChangeType.update
            let expectedNewIndexPath: IndexPath? = nil

            let delegate =
                TestDelegate(expControllerWillChangeResultsCalled: expControllerWillChangeResultsCalled,
                             expDidChangeObcAtIndexPathCalled: expDidChangeObcAtIndexPathCalled,
                             expectedIndexPath: expectedIndexPath,
                             expectedChangeType: expectedChangeType,
                             expectedNewIndexPath: expectedNewIndexPath,
                             expControllerDidChangeResultsCalled: expControllerDidChangeResultsCalled)

            let testee = QueryResultsController<CdMessage>(predicate: nil,
                                                           context: moc,
                                                           cacheName: nil,
                                                           sortDescriptors: [sortDescriptor],
                                                           delegate: delegate)
            do {
                // Start listening ...
                try testee.startMonitoring()
                XCTAssertEqual(try? testee.getResults().count, expectedResultsBefore.count)
                // Is the delegate called?
                modifyee.shortMessage = "random modification"
                try moc.save()
            } catch {
                XCTFail("throws unexpectedly")
            }

            waitForExpectations(timeout: TestUtil.waitTime) { error in
                guard error == nil else {
                    XCTFail()
                    return
                }
            }

            do {
                let resultsAfter = try testee.getResults()
                XCTAssertEqual(resultsAfter.count, expectedResultsAfter.count)
            } catch {
                XCTFail("throws unexpectedly")
            }
        }
    }

    // DID MOVE

    func testDidMoveCalled() {
        moc.performAndWait {
            // Create 3 messages
            let msg1 = TestUtil.createMessage(moc: moc)
            let msg2 = TestUtil.createMessage(moc: moc)
            let msg3 = TestUtil.createMessage(moc: moc)
            let expectedResultsBefore = [msg1, msg2, msg3]
            let expectedResultsAfter = [msg1, msg3, msg2]
            do {
                try moc.save()
            } catch {
                XCTFail()
            }
            let modifyee = msg2
            guard let idxBefore = expectedResultsBefore.firstIndex(of: modifyee) else {
                XCTFail("invalid state")
                return
            }

            guard let idxAfter = expectedResultsAfter.firstIndex(of: modifyee) else {
                XCTFail("invalid state")
                return
            }

            let expControllerWillChangeResultsCalled =
                expectation(description: "expControllerWillChangeResultsCalled")

            let expDidChangeObcAtIndexPathCalled =
                expectation(description: "expDidChangeObcAtIndexPathCalled")

            let expControllerDidChangeResultsCalled =
                expectation(description: "expControllerDidChangeResultsCalled")

            let expectedIndexPath: IndexPath? = IndexPath(row: idxBefore, section: 0)

            let expectedChangeType = NSFetchedResultsChangeType.move
            let expectedNewIndexPath: IndexPath? = IndexPath(row: idxAfter, section: 0)

            let delegate =
                TestDelegate(expControllerWillChangeResultsCalled: expControllerWillChangeResultsCalled,
                             expDidChangeObcAtIndexPathCalled: expDidChangeObcAtIndexPathCalled,
                             expectedIndexPath: expectedIndexPath,
                             expectedChangeType: expectedChangeType,
                             expectedNewIndexPath: expectedNewIndexPath,
                             expControllerDidChangeResultsCalled: expControllerDidChangeResultsCalled)

            let testee = QueryResultsController<CdMessage>(predicate: nil,
                                                           context: moc,
                                                           cacheName: nil,
                                                           sortDescriptors: [sortDescriptor],
                                                           delegate: delegate)
            do {
                // Start listening ...
                try testee.startMonitoring()
                XCTAssertEqual(try? testee.getResults().count, expectedResultsBefore.count)
                // Is the delegate called?
                modifyee.sent = Date().addingTimeInterval(1.0) // Change order
                try moc.save()
            } catch {
                XCTFail("throws unexpectedly")
            }

            waitForExpectations(timeout: TestUtil.waitTime) { error in
                guard error == nil else {
                    XCTFail()
                    return
                }
            }

            do {
                let resultsAfter = try testee.getResults()
                XCTAssertEqual(resultsAfter.count, expectedResultsAfter.count)
            } catch {
                XCTFail("throws unexpectedly")
            }
        }
    }

    // MARK: - POC: Use on non-main queue with private MOC (POC for IOS-1813)

    func testPocCanBeUsedOnPrivateContext() {
        let privateMoc: NSManagedObjectContext = Stack.shared.newPrivateConcurrentContext

        // Assure QueryResultsController can be used in background on private MOC
        let expFRCUpdated = expectation(description: "expFRCUpdated")
        let predicate =  CdMessage.PredicateFactory.unread(value: true)
        let testQRCDelegate = TestDelegate(expDidChangeObcAtIndexPathCalled: expFRCUpdated)
        let testee = QueryResultsController<CdMessage>(predicate: predicate,
                                                       context: privateMoc,
                                                       cacheName: nil,
                                                       sortDescriptors: [sortDescriptor],
                                                       delegate: testQRCDelegate)
        var expectedResults = [CdMessage]()
        privateMoc.performAndWait {
            try! testee.startMonitoring()

            XCTAssertEqual(0, try! testee.getResults().count)

            let msg = TestUtil.createMessage(moc: privateMoc)
            msg.imapFields().localFlags?.flagSeen = false
            try! privateMoc.save()
            expectedResults = [msg]
        }
        waitForExpectations(timeout: TestUtil.waitTime)
        XCTAssertTrue(expectedResults.count > 0)
        XCTAssertEqual(expectedResults.count, try! testee.getResults().count)
    }

    func testPocCanBeUsedOnBackgroundQueue() {
        let privateMoc: NSManagedObjectContext = Stack.shared.newPrivateConcurrentContext

        // Assure QueryResultsController can be used in background on private MOC
        let expFRCUpdated = expectation(description: "expFRCUpdated")
        let predicate =  CdMessage.PredicateFactory.unread(value: true)
        let testQRCDelegate = TestDelegate(expDidChangeObcAtIndexPathCalled: expFRCUpdated)
        let testee = QueryResultsController<CdMessage>(predicate: predicate,
                                                       context: privateMoc,
                                                       cacheName: nil,
                                                       sortDescriptors: [sortDescriptor],
                                                       delegate: testQRCDelegate)
        var expectedResults = [CdMessage]()

        let queue = DispatchQueue.global()
        queue.async {
            privateMoc.performAndWait {
                try! testee.startMonitoring()

                XCTAssertEqual(0, try! testee.getResults().count)

                let msg = TestUtil.createMessage(moc: privateMoc)
                msg.imapFields().localFlags?.flagSeen = false
                expectedResults = [msg]

                try! privateMoc.save()
            }
        }
        waitForExpectations(timeout: TestUtil.waitTime)

        XCTAssertTrue(expectedResults.count > 0)
        XCTAssertEqual(expectedResults.count, try! testee.getResults().count)
    }
}

// MARK: - HELPER

extension QueryResultsControllerTest {

    private func assertQueryResults(areEqualTo expectedResults: [CdMessage],
                                    mocToFetchWith: NSManagedObjectContext? = nil,

                                    expControllerWillChangeResultsCalled: XCTestExpectation? = nil,
                                    expDidChangeObcAtIndexPathCalled: XCTestExpectation? = nil,
                                    expectedIndexPath: IndexPath? = nil,
                                    expectedChangeType: NSFetchedResultsChangeType? = nil,
                                    expectedNewIndexPath: IndexPath? = nil,
                                    expControllerDidChangeResultsCalled: XCTestExpectation? = nil) {
        let delegate = TestDelegate(expControllerWillChangeResultsCalled: expControllerWillChangeResultsCalled,
                                    expDidChangeObcAtIndexPathCalled: expDidChangeObcAtIndexPathCalled,
                                    expectedIndexPath: expectedIndexPath,
                                    expectedChangeType: expectedChangeType,
                                    expectedNewIndexPath: expectedIndexPath,
                                    expControllerDidChangeResultsCalled: expControllerDidChangeResultsCalled)

        let testee = QueryResultsController<CdMessage>(predicate: nil,
                                                       context: mocToFetchWith ?? moc,
                                                       cacheName: nil,
                                                       sortDescriptors: [sortDescriptor],
                                                       delegate: delegate)
        do {
            try testee.startMonitoring()
            let results: [CdMessage] = try testee.getResults()
            XCTAssertEqual(results.count, expectedResults.count)
            for result in results {
                XCTAssertTrue(expectedResults
                    .map { $0.uuid }
                    .contains(result.uuid))
            }
        } catch {
            XCTFail("throws unexpectedly")
        }
    }
}

// MARK: - QueryResultsControllerDelegate

extension QueryResultsControllerTest {

    class TestDelegate: QueryResultsControllerDelegate {

        func queryResultsControllerDidChangeSection(Info: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
            //tbi
        }

        //
        let expControllerWillChangeResultsCalled: XCTestExpectation?
        //
        let expDidChangeObcAtIndexPathCalled: XCTestExpectation?
        let expectedIndexPath: IndexPath?
        let expectedChangeType: NSFetchedResultsChangeType?
        let expectedNewIndexPath: IndexPath?
        //
        let expControllerDidChangeResultsCalled: XCTestExpectation?

        /// - Parameters:
        ///   - expetedThread: thread we assume delegate methods are called on
        ///   - expControllerWillChangeResultsCalled: nil == we do not care
        ///   - expDidChangeObcAtIndexPathCalled: nil == we do not care
        ///   - expectedIndexPath: nil == we do not care
        ///   - expectedChangeType: nil == we do not care
        ///   - expectedNewIndexPath: nil == we do not care
        ///   - expControllerDidChangeResultsCalled: nil == we do not care
        init(expControllerWillChangeResultsCalled: XCTestExpectation? = nil,
             expDidChangeObcAtIndexPathCalled: XCTestExpectation? = nil,
             expectedIndexPath: IndexPath? = nil,
             expectedChangeType: NSFetchedResultsChangeType? = nil,
             expectedNewIndexPath: IndexPath? = nil,
             expControllerDidChangeResultsCalled: XCTestExpectation? = nil) {
            self.expControllerWillChangeResultsCalled = expControllerWillChangeResultsCalled
            self.expDidChangeObcAtIndexPathCalled = expDidChangeObcAtIndexPathCalled
            self.expectedIndexPath = expectedIndexPath
            self.expectedChangeType = expectedChangeType
            self.expectedNewIndexPath = expectedNewIndexPath
            self.expControllerDidChangeResultsCalled = expControllerDidChangeResultsCalled
        }

        // MARK: - QueryResultsControllerDelegate

        func queryResultsControllerWillChangeResults() {
            if let exp = expControllerWillChangeResultsCalled {
                exp.fulfill()
            }
        }

        func queryResultsControllerDidChangeObjectAt(indexPath: IndexPath?,
                                                     forChangeType changeType: NSFetchedResultsChangeType,
                                                     newIndexPath: IndexPath?) {
            if let exp = expDidChangeObcAtIndexPathCalled {
                exp.fulfill()
            }
            if let expectedIndexPath = expectedIndexPath {
                XCTAssertEqual(expectedIndexPath, indexPath)
            }
            if let expectedChangeType = expectedChangeType {
                XCTAssertEqual(expectedChangeType, changeType)
            }
            if let expectedNewIndexPath = expectedNewIndexPath {
                XCTAssertEqual(expectedNewIndexPath, newIndexPath)
            }
        }

        func queryResultsControllerDidChangeResults() {
            if let exp = expControllerDidChangeResultsCalled {
                exp.fulfill()
            }
        }
    }
}
