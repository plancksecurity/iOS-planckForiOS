//
//  SortedSetTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 05.10.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

struct TestObject: Equatable {
    let date: Date
    let str:String

    static func ==(lhs: TestObject, rhs: TestObject) -> Bool {
        return lhs.date == rhs.date &&
            lhs.str == rhs.str
    }
}

class SortedSetTest: XCTestCase {
    let oneDay:TimeInterval = 60 * 60 * 24
    var testObjects = [TestObject]()
    var setSortedByDate: SortedSet<TestObject>?
    var setSortedByString: SortedSet<TestObject>?

    override func setUp() {
        let now = Date()
        let yesterday = now.addingTimeInterval(-oneDay)
        let tomorrow = now.addingTimeInterval(oneDay)
        let obj1 = TestObject(date: now, str: "1")
        let obj2 = TestObject(date: yesterday, str: "2")
        let obj3 = TestObject(date: tomorrow, str: "3")
        testObjects = [obj1, obj2, obj3]

        setSortedByDate = SortedSet(array: testObjects) { (obj1: TestObject, obj2: TestObject) -> ComparisonResult in
            if obj1.date < obj2.date {
                return .orderedAscending
            } else if obj1.date > obj2.date {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
        setSortedByString = SortedSet(array: testObjects) { (obj1: TestObject, obj2: TestObject) -> ComparisonResult in
            if obj1.str < obj2.str {
                return .orderedAscending
            } else if obj1.str > obj2.str {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
    }

    // MARK: String Sorting

    func testStringSorting() {
        guard let testeeSortedByString = setSortedByString else {
            XCTFail("No test data")
            return
        }
        for i in 0..<testeeSortedByString.count - 1 {
           guard let first = testeeSortedByString.object(at: i),
            let second = testeeSortedByString.object(at: i + 1) else {
                XCTFail("No data.")
                return
            }
            XCTAssertTrue(first.str <= second.str)
        }
    }

    func testStringSorting2() {
        guard let testeeSortedByString = setSortedByString else {
            XCTFail("No test data")
            return
        }
        for i in 0..<testeeSortedByString.count - 1 {
            guard let first = testeeSortedByString.object(at: i),
                let second = testeeSortedByString.object(at: i + 1) else {
                    XCTFail("No data.")
                    return
            }
            XCTAssertFalse(first.str > second.str)
        }
    }

    // MARK: Date Sorting

    func testDateSorting() {
        guard let testeeSortedByDate = setSortedByDate else {
            XCTFail("No test data")
            return
        }
        for i in 0..<testeeSortedByDate.count - 1 {
            guard let first = testeeSortedByDate.object(at: i),
                let second = testeeSortedByDate.object(at: i + 1) else {
                    XCTFail("No data.")
                    return
            }
            XCTAssertTrue(first.date <= second.date)
        }
    }

    func testDateSorting2() {
        guard let testeeSortedByDate = setSortedByDate else {
            XCTFail("No test data")
            return
        }
        for i in 0..<testeeSortedByDate.count - 1 {
            guard let first = testeeSortedByDate.object(at: i),
                let second = testeeSortedByDate.object(at: i + 1) else {
                    XCTFail("No data.")
                    return
            }
            XCTAssertFalse(first.date > second.date)
        }
    }

    // MARK: Count

    func testCount() {
        XCTAssertEqual(testObjects.count, setSortedByString?.count)
    }

    // MARK: Insert

    func testInsertDate() {
        let lastWeek = TestObject(date: Date().addingTimeInterval(-7 * oneDay), str: "last week")
        let indexInserted = setSortedByDate?.insert(object: lastWeek)
        XCTAssertEqual(indexInserted, 0)
    }

    func testInsertDate2() {
        let nextWeek = TestObject(date: Date().addingTimeInterval(7 * oneDay), str: "last week")
        let indexInserted = setSortedByDate?.insert(object: nextWeek)
        XCTAssertNotEqual(indexInserted, 0)
    }
}
