//
//  MessageQueryResultsSearch.swift
//  MessageModelTests
//
//  Created by Xavier Algarra on 28/02/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel

class MessageQueryResultsSearchTest: XCTestCase {

    func testSearchPredicate() {
        let mqrs = MessageQueryResultsSearch(searchTerm: "text")
        XCTAssertEqual(CdMessage.PredicateFactory.messageContains(value: "text"), mqrs.predicate)
    }
}
