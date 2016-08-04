//
//  ReplyUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public struct ReplyUtil {
    static let nameSeparator = ", "
    static let newline = "\n"

    public static func replyNameFromContact(contact: IContact) -> String {
        if let name = contact.name {
            return name
        }
        return contact.email
    }

    public static func quoteText(text: String) -> String {
        let newLineCS = NSCharacterSet.init(charactersInString: newline)
        let lines = text.componentsSeparatedByCharactersInSet(newLineCS)
        let quoted = lines.map() {
            return "> \($0)"
        }
        let quotedText = quoted.joinWithSeparator(newline)
        return quotedText
    }

    public static func citationHeaderForMessage(message: IMessage, replyAll: Bool) -> String {
        let dateFormatter = NSDateFormatter.init()
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.LongStyle

        let theDate = message.receivedDate

        var theNames = [String]()
        if replyAll {
            let contacts = message.allRecipienst().array
            theNames.appendContentsOf(
                contacts.map() { return replyNameFromContact($0 as! IContact) })
        } else {
            if let from = message.from {
                theNames.append(replyNameFromContact(from))
            }
        }

        if theNames.count == 0 {
            if let rd = theDate {
                return NSLocalizedString(
                    String.init(format: "Someone wrote on %@:",
                        dateFormatter.stringFromDate(rd)),
                    comment: "Reply to unknown sender with date")
            } else {
                return NSLocalizedString("Someone wrote:",
                                         comment: "Reply to unknown sender without date")
            }
        } else if theNames.count == 1 {
            if let rd = theDate {
                return NSLocalizedString(
                    String.init(format: "%@ wrote on %@:",
                        theNames[0], dateFormatter.stringFromDate(rd)),
                    comment: "Reply to single contact, with date")
            } else {
                return NSLocalizedString(
                    String.init(format: "%@ wrote:",
                        theNames[0]),
                    comment: "Reply to single contact, without date")
            }
        } else {
            let allNames = theNames.joinWithSeparator(nameSeparator)
            if let rd = theDate {
                return NSLocalizedString(
                    String.init(format: "%@ wrote on %@:",
                        allNames, dateFormatter.stringFromDate(rd)),
                    comment: "Reply to multiple contacts, with date")
            } else {
                return NSLocalizedString(
                    String.init(format: "%@ wrote:",
                        allNames),
                    comment: "Reply to multiple contacts, without date")
            }
        }
    }

    public static func footer() -> String {
        return NSLocalizedString("Sent with p≡p",
                                 comment: "Mail footer/default text")
    }

    public static func quotedMailTextForMail(mail: IMessage, replyAll: Bool) -> String {
        if let text = mail.longMessage {
            let quotedText = quoteText(text)
            let citation: String? = citationHeaderForMessage(mail, replyAll: replyAll)
            if let c = citation {
                return "\n\(footer())\n\n\(c)\n\n\(quotedText)"
            }
        }
        return footer()
    }
}