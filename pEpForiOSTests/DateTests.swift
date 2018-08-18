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
            reWeekday = try NSRegularExpression(pattern: "^(\\w+)$", options: [])
            reTime = try NSRegularExpression(pattern: "^\\d\\d?:\\d\\d (?:A|P)M$",
                                                  options: [])
            reDate = try NSRegularExpression(pattern: "^\\w+ \\d\\d?, \\d\\d\\d\\d$",
                                                  options: [])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func matchesWhole(re: NSRegularExpression?, string: String?) -> Bool {
        if let r = re {
            return r.matchesWhole(string: string)
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
