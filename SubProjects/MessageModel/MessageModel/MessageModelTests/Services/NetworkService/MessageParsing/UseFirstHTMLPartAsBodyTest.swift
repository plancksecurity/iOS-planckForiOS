//
//  UseFirstHTMLPartAsBodyTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 27.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData

import PantomimeFramework
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS
@testable import MessageModel
import pEpIOSToolbox

class UseFirstHTMLPartAsBodyTest: PersistentStoreDrivenTestBase {
    let onlyContainedInBody = "This is a real HTML mail"
    let onlyContainedInAttachment = "Lorem ipsum dolor sit amet"

    func testParsingHtmlBodyWithHtmlAttachent() {
        checkParsingHtmlBodyWithHtmlAttachent(
            fileName: "IOS-1556_html_mail_with_html_attachment.txt",
            onlyContainedInBody: onlyContainedInBody,
            onlyContainedInAttachment: onlyContainedInAttachment,
            numberOfAttachments: 1)
    }

    func testParsingHtmlBodyWithInlineHtmlAttachent() {
        checkParsingHtmlBodyWithHtmlAttachent(
            fileName: "IOS-1556_html_mail_with_html_attachment_inline.txt",
            onlyContainedInBody: onlyContainedInBody,
            onlyContainedInAttachment: onlyContainedInAttachment,
            numberOfAttachments: 1)
    }

    func testParsingHtmlBodyWithInlineHtmlMixed() {
        checkParsingHtmlBodyWithHtmlAttachent(
            fileName: "IOS-1556_html_mail_with_html_attachments_mixed.txt",
            onlyContainedInBody: onlyContainedInBody,
            onlyContainedInAttachment: onlyContainedInAttachment,
            numberOfAttachments: 2)
    }
}

// MARK: -- Test Drivers

extension UseFirstHTMLPartAsBodyTest {
    func checkParsingHtmlBodyWithHtmlAttachent(
        fileName: String,
        onlyContainedInBody: String,
        onlyContainedInAttachment: String,
        numberOfAttachments: Int) {
        guard let cdMsg = UseFirstHTMLPartAsBodyTest.cdMessage(
            fileName: fileName,
            cdOwnAccount: cdAccount) else {
                XCTFail()
                return
        }
        XCTAssertTrue(
            (cdMsg.longMessageFormatted ?? "").contains(find: onlyContainedInBody))
        XCTAssertFalse(
            (cdMsg.longMessageFormatted ?? "").contains(find: onlyContainedInAttachment))

        guard let attachments = cdMsg.attachments?.array as? [CdAttachment] else {
            XCTFail()
            return
        }
        XCTAssertEqual(attachments.count, numberOfAttachments)

        for cdAttch in attachments {
            XCTAssertEqual(cdAttch.mimeType, "text/html")

            guard let attachmentData = cdAttch.data else {
                XCTFail()
                return
            }

            guard let htmlTextFromAttachment = String(data: attachmentData, encoding: .utf8) else {
                XCTFail()
                return
            }

            XCTAssertFalse(htmlTextFromAttachment.contains(find: onlyContainedInBody))
            XCTAssertTrue(htmlTextFromAttachment.contains(find: onlyContainedInAttachment))
        }
    }
}

// MARK: -- Helpers

extension UseFirstHTMLPartAsBodyTest {
    static func loadData(fileName: String) -> Data? {
        return MiscUtil.loadData(bundleClass: self, fileName: fileName)
    }

    static func loadString(fileName: String) -> String? {
        if let data = loadData(fileName: fileName) {
            guard let content = NSString(data: data, encoding: String.Encoding.ascii.rawValue)
                else {
                    XCTAssertTrue(
                        false, "Could not convert key with file name \(fileName) into data")
                    return nil
            }
            return content as String
        }
        return nil
    }

    /**
     Loads the given file by name and parses it into a pantomime message.
     */
    static func cwImapMessage(fileName: String) -> CWIMAPMessage? {
        guard
            var msgTxtData = UseFirstHTMLPartAsBodyTest.loadData(
                fileName: fileName)
            else {
                XCTFail()
                return nil
        }

        // This is what pantomime does with everything it receives
        msgTxtData = replacedCRLFWithLF(data: msgTxtData)

        let pantomimeMail = CWIMAPMessage(data: msgTxtData, charset: "UTF-8")
        pantomimeMail?.setUID(5) // some random UID out of nowhere
        pantomimeMail?.setFolder(CWIMAPFolder(name: ImapConnection.defaultInboxName))

        return pantomimeMail
    }

    /**
     Loads the given file by name, parses it with pantomime and creates a CdMessage from it.
     */
    static func cdMessage(fileName: String, cdOwnAccount: CdAccount) -> CdMessage? {
        guard let pantomimeMail = cwImapMessage(fileName: fileName) else {
            XCTFail()
            return nil
        }

        let moc: NSManagedObjectContext = Stack.shared.mainContext
        guard let cdMessage = CdMessage.insertOrUpdate(pantomimeMessage: pantomimeMail,
                                                       account: cdOwnAccount,
                                                       messageUpdate: CWMessageUpdate(),
                                                       context: moc)
            else {
                XCTFail()
                return nil
        }
        XCTAssertEqual(cdMessage.pEpRating, Int16(PEPRating.undefined.rawValue))

        return cdMessage
    }

    static func replacedCRLFWithLF(data: Data) -> Data {
        let mData = NSMutableData(data: data)
        mData.replaceCRLFWithLF()
        return mData as Data
    }
}
