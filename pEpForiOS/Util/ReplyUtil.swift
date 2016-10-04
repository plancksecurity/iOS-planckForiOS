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

    public static func replyNameFromContact(_ contact: CdContact) -> String {
        if let name = contact.name {
            return name
        }
        return contact.email
    }

    public static func quoteText(_ text: String) -> String {
        let newLineCS = CharacterSet.init(charactersIn: newline)
        let lines = text.components(separatedBy: newLineCS)
        let quoted = lines.map() {
            return "> \($0)"
        }
        let quotedText = quoted.joined(separator: newline)
        return quotedText
    }

    public static func citationHeaderForMessage(_ message: CdMessage, replyAll: Bool) -> String {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateStyle = DateFormatter.Style.long
        dateFormatter.timeStyle = DateFormatter.Style.long

        let theDate = message.receivedDate

        var theNames = [String]()
        if replyAll {
            let contacts = message.allRecipienst().array
            theNames.append(
                contentsOf: contacts.map() { return replyNameFromContact($0 as! CdContact) })
        } else {
            if let from = message.from {
                theNames.append(replyNameFromContact(from))
            }
        }

        if theNames.count == 0 {
            if let rd = theDate {
                return String.init(format: NSLocalizedString("Someone wrote on %@:", comment: "Reply to unknown sender with date"),
                                   dateFormatter.string(from: rd as Date))
            } else {
                return NSLocalizedString("Someone wrote:",
                                         comment: "Reply to unknown sender without date")
            }
        } else if theNames.count == 1 {
            if let rd = theDate {
                return String.init(
                    format: NSLocalizedString(
                        "%@ wrote on %@:", comment: "Reply to single contact, with date"),
                    theNames[0], dateFormatter.string(from: rd as Date))
            } else {
                return String.init(
                    format: NSLocalizedString(
                        "%@ wrote:", comment: "Reply to single contact, without date"),
                    theNames[0])
            }
        } else {
            let allNames = theNames.joined(separator: nameSeparator)
            if let rd = theDate {
                return String.init(
                    format: NSLocalizedString(
                        "%@ wrote on %@:",
                        comment: "Reply to multiple contacts, with date"),
                    allNames, dateFormatter.string(from: rd as Date))
            } else {
                return String.init(
                    format: NSLocalizedString(
                        "%@ wrote:", comment: "Reply to multiple contacts, without date"),
                    allNames)
            }
        }
    }

    public static func footer() -> String {
        return NSLocalizedString("Sent with p≡p",
                                 comment: "Mail footer/default text")
    }

    public static func quotedMailTextForMail(_ mail: CdMessage, replyAll: Bool) -> String {
        if let text = mail.longMessage {
            let quotedText = quoteText(text)
            let citation: String? = citationHeaderForMessage(mail, replyAll: replyAll)
            if let c = citation {
                return "\n\n\(footer())\n\n\(c)\n\n\(quotedText)"
            }
        }
        return footer()
    }

    public static func replySubjectForMail(_ mail: CdMessage) -> String {
        if let subject = mail.subject {
            let re = NSLocalizedString(
                "Re: ", comment: "The 'Re:' that gets appended to the subject line")
            return "\(re) \(subject)"
        } else {
            return ""
        }
    }
}
