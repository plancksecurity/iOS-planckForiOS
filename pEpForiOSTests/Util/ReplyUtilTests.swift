//
//  ReplyUtilTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 05.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

// ReplyUtilsTest code coverage ~80% on date 20200228

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
    // Create new ticket for this bug?
    func testReplyNonSubject() {
        let msg = getMockMessage()
        msg.shortMessage = nil
        let exp = Constant.expectedReplyPrefix + " "
        let sth = ReplyUtil.replySubject(message: msg)
        XCTAssertEqual(sth, exp,
                       showDifference(string1: sth, string2: exp, onlyFirstChar: true))
        // Failed! Current implementation is wrong.
        // XCTAssertEqual failed: ("") is not equal to ("Re:  ")
    }

    // Create new ticket for this bug?
    func testForwardSubject() {
        let msg = getMockMessage()
        msg.shortMessage = Constant.crazySpaces + Constant.subject
        let sth = ReplyUtil.forwardSubject(message: msg)
        let exp = Constant.expectedForwardPrefix
        XCTAssertEqual(sth, exp,
                       showDifference(string1: sth, string2: exp, onlyFirstChar: true))
        // Failed! Current implementation is wrong.
        // XCTAssertEqual failed: ("Fwd:       This is a subject") is not equal to ("Fwd: ")
    }

    // Create new ticket for this bug?
    func testForwardNonSubject() {
        let msg = getMockMessage()
        msg.shortMessage = nil
        let exp = Constant.expectedForwardPrefix
        let sth = ReplyUtil.forwardSubject(message: msg)
        XCTAssertEqual(sth, exp)
        // Failed! Current implementation is wrong.
        // XCTAssertEqual failed: ("") is not equal to ("Fwd:  ")
    }

    func testQuotedMessageTextEmpty() {
        let identity = Identity(address: "what@example.com",
                                userID: "userID",
                                addressBookID: nil,
                                userName: "User Name")
        let account = Account(user: identity, servers: [])
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        let msg = Message(uuid: "001", uid: 1, parentFolder: folder)
        let exp = "\n\n\(String.pepSignature)"
        let sth = ReplyUtil.quotedMessageText(message: msg, replyAll: false)
        XCTAssertEqual(sth, exp)
    }

    func testQuotedMessageTextNotEmptySentDateIsSpecified() {
        let identity = Identity(address: "what@example.com",
                                userID: "userID",
                                addressBookID: nil,
                                userName: "User Name")
        let account = Account(user: identity, servers: [])
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        let msg = Message(uuid: "001", uid: 1, parentFolder: folder)
        let sentDate = Date.init(timeIntervalSince1970: 1000000)
        msg.sent = sentDate // ~ January 12, 1970 at 2:46:40 PM GMT+1
        msg.longMessageFormatted = Constant.longMessageHtmlFormatted
        let dateString = getDateFormattedString(date: sentDate)
        let exp = "\n\n\(String.pepSignature)\n\nSomeone wrote on \(dateString):\n\n> Test\n> Test"
        let sth = ReplyUtil.quotedMessageText(message: msg, replyAll: false)
        XCTAssertEqual(sth, exp)
    }

    func testQuotedMessageTextNotEmptySentDateIsUnknown() {
        let identity = Identity(address: "what@example.com",
                                userID: "userID",
                                addressBookID: nil,
                                userName: "User Name")
        let account = Account(user: identity, servers: [])
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        let msg = Message(uuid: "001", uid: 1, parentFolder: folder)
        msg.sent = nil
        msg.longMessageFormatted = Constant.longMessageHtmlFormatted
        let exp = "\n\n\(String.pepSignature)\n\nSomeone wrote:\n\n> Test\n> Test"
        let sth = ReplyUtil.quotedMessageText(message: msg, replyAll: false)
        XCTAssertEqual(sth, exp)
    }

    // Refer to IOS-1363
    func testCitedMessageTextNotEmptySentDateIsUnknown() {
        let identity = Identity(address: "what@example.com",
                                userID: "userID",
                                addressBookID: nil,
                                userName: "User Name")
        let account = Account(user: identity, servers: [])
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        let msg = Message(uuid: "001", uid: 1, parentFolder: folder)
        msg.sent = nil
        msg.longMessageFormatted = Constant.longMessageHtmlFormatted
        let exp = "\n\n\(String.pepSignature)\n\nSomeone wrote:\n\n> Test"
        let sth = ReplyUtil.citedMessageText(textToCite: "Test", fromMessage: msg)
        XCTAssertEqual(sth, exp,
                       showDifference(string1: sth, string2: exp))
    }

    // Refer to IOS-1363
    // Failed because current implementation ReplyUtil.citedMessageText is wrong
    // We expect cited message not message without '>' characters
    func testCitedHtmlMessageTextNotEmptySentDateIsUnknown() {
        let identity = Identity(address: "what@example.com",
                                userID: "userID",
                                addressBookID: nil,
                                userName: "User Name")
        let account = Account(user: identity, servers: [])
        let folder = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        let msg = Message(uuid: "001", uid: 1, parentFolder: folder)
        msg.sent = nil
        let bodyHtml = Constant.longMessageHtmlFormatted
        msg.longMessageFormatted = bodyHtml
        let exp = NSAttributedString(string: "\n\n\(String.pepSignature)\n\nSomeone wrote:\n\n> Test\nTest\n")
        let sth = ReplyUtil.citedMessageText(textToCite: bodyHtml.htmlToAttributedString(attachmentDelegate: nil), fromMessage: msg)
        XCTAssertEqual(sth.string, exp.string,
                       showDifference(string1: sth.string, string2: exp.string))
    }
}

// MARK: - Mock Data

extension ReplyUtilTests {
    private struct Constant {
        static let footnote = String.pepSignature
        static let subject = "This is a subject"
        static let expectedReplyPrefix = "Re: " // TODO: - Re: not localized!
        static let expectedForwardPrefix = NSLocalizedString("Fwd: ",
                                                             comment: "The 'Fwd:' that gets appended to the subject line")
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
    // WIP: only temporary - this function will be removed
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
