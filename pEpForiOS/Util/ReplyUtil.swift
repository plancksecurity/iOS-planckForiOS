//
//  ReplyUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public struct ReplyUtil {
    static let nameSeparator = ", "
    static let newline = "\n"

    /**
     Gets the quoted message body for the given `Message`.
     */
    public static func quotedMessageText(message: Message, replyAll: Bool) -> String {
        if let text = message.longMessage {
            let quotedText = quoteText(text)
            let citation: String? = citationHeaderForMessage(message, replyAll: replyAll)
            if let c = citation {
                return "\n\n\(footer())\n\n\(c)\n\n\(quotedText)"
            }
        }
        return footer()
    }

    /**
     Gets the subject for replying to the given `Message`.
     */
    public static func replySubject(message: Message) -> String {
        if let subject = message.shortMessage {
            let re = NSLocalizedString(
                "Re: ", comment: "The 'Re:' that gets appended to the subject line")
            return "\(re) \(subject)"
        } else {
            return ""
        }
    }

    public static func forwardSubject(message: Message) -> String {
        if let subject = message.shortMessage {
            let re = NSLocalizedString(
                "Fwd: ", comment: "The 'Fwd:' that gets appended to the subject line")
            return "\(re) \(subject)"
        } else {
            return ""
        }
    }

    public static func replyNameFromIdentity(_ identity: Identity) -> String {
        if let name = identity.userName {
            return name
        }
        return identity.address
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

    public static func citationHeaderForMessage(_ message: Message, replyAll: Bool) -> String {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateStyle = DateFormatter.Style.long
        dateFormatter.timeStyle = DateFormatter.Style.long

        let theDate = message.received

        var theNames = [String]()
        if replyAll {
            let contacts = message.allRecipients
            theNames.append(
                contentsOf: contacts.map() { return replyNameFromIdentity($0) })
        } else {
            if let from = message.from {
                theNames.append(replyNameFromIdentity(from))
            }
        }

        if theNames.count == 0 {
            if let rd = theDate {
                return String.init(
                    format: NSLocalizedString("Someone wrote on %@:",
                                              comment: "Reply to unknown sender with date"),
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
                                 comment: "Message footer/default text")
    }
}
