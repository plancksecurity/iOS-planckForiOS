//
//  ReplyUtilTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 05.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

@testable import pEpForiOS
@testable import MessageModel

class ReplyUtilTests: XCTestCase {

    func testRepliesSubject() {
        let msg = getMockMessage()
        let subject = Constant.subject
        let expectedReplySubject = Constant.expectedReplyPrefix + Constant.subject
        var theSubject = subject
        for _ in 1...5 {
            theSubject = "\(Constant.crazySpaces)Re:  \(theSubject)"
            msg.shortMessage = theSubject
            XCTAssertEqual(ReplyUtil.replySubject(message: msg), expectedReplySubject)
        }
        XCTAssertEqual(ReplyUtil.replySubject(message: msg), expectedReplySubject)
    }

    func testReplyNonSubject() {
        let msg = getMockMessage()
        msg.shortMessage = nil
        let exp = Constant.expectedReplyPrefixForEmptySubject
        let sth = ReplyUtil.replySubject(message: msg)
        XCTAssertEqual(sth, exp,
                       showDifference(string1: sth, string2: exp, onlyFirstChar: true))
    }

    func testForwardSubject() {
        let msg = getMockMessage()
        msg.shortMessage = Constant.crazySpaces + Constant.subject
        let sth = ReplyUtil.forwardSubject(message: msg)
        let exp = Constant.expectedForwardPrefix + Constant.subject
        XCTAssertEqual(sth, exp,
                       showDifference(string1: sth, string2: exp, onlyFirstChar: true))
    }

    func testForwardNonSubject() {
        let msg = getMockMessage()
        msg.shortMessage = nil
        let exp = Constant.expectedForwardPrefixForEmptySubject
        let sth = ReplyUtil.forwardSubject(message: msg)
        XCTAssertEqual(sth, exp)
    }
}

// MARK: - Mock Data

extension ReplyUtilTests {
    private struct Constant {
        static let footnote = String.pepSignature
        static let subject = "This is a subject"
        static let expectedReplyPrefix = "Re: "
        static let expectedReplyPrefixForEmptySubject = ""
        static let expectedForwardPrefix = "Fwd: "
        static let expectedForwardPrefixForEmptySubject = ""
        static let longMessageHtmlFormatted = "<html><body><p>Test</p><p>Test</p></body></html>"
        static let crazySpaces = "     "
    }
    private func getDateFormattedString(date: Date) -> String {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateStyle = DateFormatter.Style.long
        dateFormatter.timeStyle = DateFormatter.Style.long
        return dateFormatter.string(from: date as Date)
    }
    private func getMockMessage() -> Message {
        let identity = Identity(address: "what@example.com",
                                userID: "userID",
                                addressBookID: nil,
                                userName: "User Name")
        let account = Account(user: identity, servers: [])
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        return Message(uuid: "001", uid: 1, parentFolder: folder)
    }

    private func showDifference(string1: String, string2: String, onlyFirstChar: Bool = false) -> String {
        let difference = zip(string1, string2).filter { $0 != $1 }
        var diff1 = ""
        var diff2 = ""
        for diffLine in difference {
            diff1 += String(visibleSpace(char: diffLine.0))
            diff2 += String(visibleSpace(char: diffLine.1))
            if onlyFirstChar {
                break
            }
        }
        return "Unexpected differences: \(diff1) != \(diff2)"
    }
    private func visibleSpace(char: Character) -> Character {
        return char == Character(" ") ? "_" : char
    }
}
