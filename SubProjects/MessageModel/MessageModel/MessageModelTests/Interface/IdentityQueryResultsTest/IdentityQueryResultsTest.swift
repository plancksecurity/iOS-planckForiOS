//
//  IdentityQueryResultsTest.swift
//  MessageModelTests
//
//  Created by Xavier Algarra on 23/09/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData
@testable import MessageModel

class IdentityQueryResultTest: PersistentStoreDrivenTestBase {
    var identityQueryResult: IdentityQueryResults?

    override func setUp() {
        super.setUp()

        //there is no identities
        let ids = CdIdentity.all(in: moc) as? [CdIdentity]
        guard let nonOptionalIds = ids else {
            XCTFail()
            return
        }
        for id in nonOptionalIds  {
            moc.delete(id)
        }
        try? moc.save()

        identityQueryResult = IdentityQueryResults()
    }

    override func tearDown() {
        identityQueryResult?.rowDelegate = nil
        identityQueryResult = nil
        super.tearDown()
    }

    func testInit() {
        // When
        let identityQueryResult = IdentityQueryResults()

        // Then
        XCTAssertNotNil(identityQueryResult)
    }

    func testStartMonitoringWithOutElements() {
        // Given
        guard let identityQueryResults = identityQueryResult else {
            XCTFail()
            return
        }

        // When
        guard let _ = try? identityQueryResults.startMonitoring() else {
            XCTFail()
            return
        }

        // Then
        let expectedMessagesCount = 0
        XCTAssertEqual(try? identityQueryResults.count(), expectedMessagesCount)
    }

    func testStartMonitoringWithElements() {
        // Given
        guard let identityQueryResults = identityQueryResult else {
            XCTFail()
            return
        }
        //create 1 identity
        _ = SecretTestData().createWorkingCdIdentity()
        try? moc.save()

        // When
        guard let _ = try? identityQueryResults.startMonitoring() else {
            XCTFail()
            return
        }
        // Then
        let expectedIdentitiesCount = 1
        let identitiesCount = try! identityQueryResults.count()
        XCTAssertEqual(identitiesCount, expectedIdentitiesCount)
        for i in 1..<identitiesCount {
            XCTAssertTrue(type(of: identityQueryResults[i]) ==  Identity.self)
        }
    }

    func SubscriptTest() {
        // Given
        guard let identityQueryResults = identityQueryResult else {
            XCTFail()
            return
        }

        let identities = createCdIdentities(numIdentities: 10, context: moc)

        // When
        guard let _ = try? identityQueryResults.startMonitoring() else {
            XCTFail()
            return
        }

        // Then
        XCTAssertTrue(type(of: identities[0]) == Identity.self)
        XCTAssertEqual(identities[1].userID, "1")
        XCTAssertEqual(identities[2].userID, "2")
        XCTAssertEqual(identities[3].userID, "3")
    }
}

extension IdentityQueryResultTest {

    @discardableResult
    private func createCdIdentities(numIdentities: Int = 1,
                                    context: NSManagedObjectContext = Stack.shared.mainContext) -> [CdIdentity] {
        var identities = [CdIdentity]()
        for n in 0...numIdentities {
            let identity = TestUtil.createIdentity(idAddress: "\(n)@test", idUserName: "\(n)", moc: moc)
            identities.append(identity)
        }
        context.saveAndLogErrors()
        return identities
    }
}

// MARK: - Delegate test class

class IdentityQueryResultTestDelegate {
    let exp: XCTestExpectation
    let expType: expectationType

    var didMove = false
    var didInsert = false
    var didUpdate = false
    var didDelete = false
    var willChange = false
    var didChange = false
    var didInsertSection = false
    var didDeleteSection = false
    var indexPath: IndexPath?
    var newIndexPath: IndexPath?

    enum expectationType {
        case didInsert, didUpdate, didDelete, didMove, willChange, didChange, didInsertSection, didDeleteSection
    }

    init(withExp exp: XCTestExpectation, expType: expectationType) {
        self.exp = exp
        self.expType = expType
    }
}

// MARK: - QueryResultsDelegate

extension IdentityQueryResultTestDelegate: QueryResultsIndexPathRowDelegate {
    func didInsertRow(indexPath: IndexPath) {
        // 
    }

    func didInsertCell(indexPath: IndexPath) {
        didInsert = true
        self.indexPath = indexPath
        if expType == .didInsert { exp.fulfill() }
    }

    func didUpdateRow(indexPath: IndexPath) {
        didUpdate = true
        self.indexPath = indexPath
        if expType == .didUpdate { exp.fulfill() }
    }

    func didDeleteRow(indexPath: IndexPath) {
        didDelete = true
        self.indexPath = indexPath
        if expType == .didDelete { exp.fulfill() }
    }

    func didMoveRow(from: IndexPath, to: IndexPath) {
        didMove = true
        indexPath = from
        newIndexPath = to
        if expType == .didMove { exp.fulfill() }
    }

    func willChangeResults() {
        willChange = true
        if expType == .willChange { exp.fulfill() }
    }

    func didChangeResults() {
        didChange = true
        if expType == .didChange { exp.fulfill() }
    }
}

extension IdentityQueryResultTestDelegate: QueryResultsIndexPathSectionDelegate {
    func didInsertSection(position: Int) {
        didInsertSection = true
        if expType == .didInsertSection { exp.fulfill() }
    }

    func didDeleteSection(position: Int) {
        didDeleteSection = true
        if expType == .didDeleteSection { exp.fulfill() }
    }
}
