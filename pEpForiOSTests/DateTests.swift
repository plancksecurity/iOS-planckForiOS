//
//  DateTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class DateTests: XCTestCase {
    var calender = Calendar.current
    var reWeekday: NSRegularExpression?
    var reTime: NSRegularExpression?
    var reDate: NSRegularExpression?

    override func setUp() {
        calender.locale = Locale(identifier: "en_US")
        do {
            reWeekday = try NSRegularExpression.init(pattern: "^(\\w+)$", options: [])
            reTime = try NSRegularExpression.init(pattern: "^\\d\\d?:\\d\\d (?:A|P)M$", options: [])
            reDate = try NSRegularExpression.init(pattern: "^\\d\\d?/\\d\\d?/\\d\\d$", options: [])
        } catch let err as NSError {
            XCTFail(err.localizedDescription)
        }
    }

    func matchesWhole(re: NSRegularExpression?, string: String?) -> Bool {
        if let r = re, let s = string {
            let range = r.rangeOfFirstMatch(in: s, options: [], range: s.wholeRange())
            return NSEqualRanges(range, s.wholeRange())
        }
        return false
    }

    func isDay(string: String?) -> Bool {
        return matchesWhole(re: reWeekday, string: string)
    }

    func isTime(string: String?) -> Bool {
        return matchesWhole(re: reTime, string: string)
    }

    func isDate(string: String?) -> Bool {
        return matchesWhole(re: reDate, string: string)
    }

    func testStrings() {
        let today = Date()
        XCTAssertTrue(isTime(string: today.smartString()))
        XCTAssertTrue(isDay(string: calender.date(
            byAdding: .day, value: -3, to: today)?.smartString()))
        XCTAssertTrue(isDay(string: calender.date(
            byAdding: .day, value: -6, to: today)?.smartString()))
        XCTAssertTrue(isDate(string: calender.date(
            byAdding: .day, value: -7, to: today)?.smartString()))
    }
}
