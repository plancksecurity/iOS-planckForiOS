//
//  MessageQueryResultsFilter.swift
//  MessageModelTests
//
//  Created by Xavier Algarra on 26/02/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel
import CoreData

//!!!: there is not single test that actually test the most important (and most error prone) thing in the Filter: the resulting messages (in other words: the predicate). A test must test the public API, act as the client and prove the Cpntract is fulfilled. All the client cares about is the filters result is correct.
class MessageQueryResultsFilterTest: PersistentStoreDrivenTestBase {
    var account2: Account!

    override func setUp() {
        super.setUp()
        account2 = SecretTestData().createWorkingCdAccount(number: 1).account()
    }

//    func testBlankFilter() {
//        // Given
    //        let mqrf = MessageQueryResultsFilter() //!!!: needs to adapt that the filter need account(s) now
//
//        // When
//        let predicates = mqrf.predicate
//
//        // Then
//        XCTAssertNil(predicates)
//    }

    func testAttributesSettedCorrectly() {
        let flagged = false
        let unread = true
        let attachments = false
        let accounts: [Account] = [account, account2]
        let mqrf = MessageQueryResultsFilter(mustBeFlagged: flagged,
                                             mustBeUnread: unread,
                                             mustContainAttachments:
            attachments, accounts: accounts)

        guard let resultUnread = mqrf.mustBeUnread else {
            XCTFail("unexpected nil value")
            return
        }
        XCTAssertEqual(unread, resultUnread)

        guard let resultFlagged = mqrf.mustBeFlagged else {
            XCTFail("unexpected nil value")
            return
        }
        XCTAssertEqual(flagged, resultFlagged)

        guard let resultAttachments = mqrf.mustContainAttachments else {
            XCTFail("unexpected nil value")
            return
        }
        XCTAssertEqual(attachments, resultAttachments)
        XCTAssertEqual(accounts, mqrf.accounts)
    }

//    func testPredicateOrPredicate() {
//        let mqrf = MessageQueryResultsFilter(mustBeFlagged: true, mustBeUnread: true)//!!!: needs to adapt that the filter need account(s) now
//        guard let predicates = mqrf.predicate as? NSCompoundPredicate else {
//            XCTFail("Must be a compound predicate")
//            return
//        }
//        XCTAssertNotEqual(predicates.compoundPredicateType, NSCompoundPredicate.LogicalType.or)
//        XCTAssertEqual(NSCompoundPredicate.LogicalType.and, predicates.compoundPredicateType)
//    }
}
