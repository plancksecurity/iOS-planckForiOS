//
//  ReplyUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public struct ReplyUtil {
    private static let nameSeparator = ", "
    private static let newline = "\n"

    /**
     Gets the quoted message body for the given `Message`.
     */
    public static func quotedMessageText(message: Message, replyAll: Bool) -> String {
        guard let quotedText = quotedText(for: message) else {
            return "\n\n\(footer())"
        }
        let citation = citationHeaderForMessage(message, replyAll: replyAll)

        return "\n\n\(footer())\n\n\(citation)\n\n\(quotedText)"
    }

    /// Adds citation header with data of a given message to a given text.
    ///
    /// - Parameters:
    ///   - textToCite: text to cite
    ///   - msg: message to take data (sender, date sent ...) from
    /// - Returns: text with citation header and "send by pEp" footer
     static func citedMessageText(textToCite: String, fromMessage msg: Message) -> String {
        let citation = citationHeaderForMessage(msg, replyAll: false)
        return "\n\n\(footer())\n\n\(citation)\n\n\(textToCite)"
    }

    /// Adds citation header with data of a given message to a given text.
    ///
    /// - Parameters:
    ///   - textToCite: text to cite
    ///   - msg: message to take data (sender, date sent ...) from
    /// - Returns: text with citation header and "send by pEp" footer
    public static func citedMessageText(textToCite: NSAttributedString,
                                        fromMessage msg: Message) -> NSAttributedString {
        let citation = citationHeaderForMessage(msg, replyAll: false)

        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        var result = NSAttributedString(string: "\n\n\(footer())\n\n\(citation)\n\n",
            attributes: [NSAttributedStringKey(rawValue: "NSFont"): defaultFont])
        result = result + textToCite
        return result
    }

    /**
     List of potential prefixes of already replied-to emails in the subject.
     See https://en.wikipedia.org/wiki/List_of_email_subject_abbreviations#Abbreviations_in_other_languages
     */
    public static let replyPrefixes = ["RE", "رد",
                                       "回复",
                                       "回覆",
                                       "SV",
                                       "Antw",
                                       "VS",
                                       "REF",
                                       "AW",
                                       "ΑΠ",
                                       "ΣΧΕΤ", "תגובה",
                                       "Vá",
                                       "R",
                                       "RIF",
                                       "SV",
                                       "BLS",
                                       "SV",
                                       "SV",
                                       "RE",
                                       "RES",
                                       "Odp",
                                       "YNT"]

    /**
     Has that subject already been prefixed with a "Re:" in one of the languages we support?
     - Note: Checks in a case-insensitive manner.
     */
    public static func hasRePrefix(subject: String) -> Bool {
        let lcSubject = subject.lowercased()

        for replyPrefix in replyPrefixes {
            if lcSubject.hasPrefix("\(replyPrefix.lowercased()): ") {
                return true
            }
        }

        return false
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
            let fwd = NSLocalizedString(
                "Fwd: ", comment: "The 'Fwd:' that gets appended to the subject line")
            return "\(fwd) \(subject)"
        } else {
            return ""
        }
    }

    // MARK: - Private

    /// Extracts the text that should be used for quoting (in reply/forwarding) from a given message and returns it in quoted form.
    /// - Parameter message: message to extract text from
    /// - Returns:  If longMessageFormatted exists: formatted message with HTML striped, in quoted form
    ///             else if longMessage exists: longMessage in quoted form
    ///             nil otherwize
    static private func quotedText(for message: Message) -> String? {
        guard let text = extractMessageTextToQuote(from: message) else {
            return nil
        }
        return quoteText(text)
    }

    /// Extracts the text that should be used for quoting (in reply/forwarding) from a given message.
    ///
    /// - Parameter message: message to extract text from
    /// - Returns:  If longMessageFormatted exists: formatted message with HTML tags are striped
    ///             else if longMessage exists: longMessage
    ///             nil otherwize
    static private func extractMessageTextToQuote(from message: Message) -> String? {
        var textToQuote = message.longMessage ?? nil
        guard let formatted = message.longMessageFormatted else {
            return textToQuote
        }
        textToQuote = formatted.extractTextFromHTML()

        return textToQuote //message.longMessage
    }

    static private func replyNameFromIdentity(_ identity: Identity) -> String {
        if let name = identity.userName {
            return name
        }
        return identity.address
    }

    static private func quoteText(_ text: String) -> String {
        let newLineCS = CharacterSet.init(charactersIn: newline)
        let lines = text.components(separatedBy: newLineCS)
        let quoted = lines.map() {
            return "> \($0)"
        }
        let quotedText = quoted.joined(separator: newline)
        return quotedText
    }

    static private func citationHeaderForMessage(_ message: Message, replyAll: Bool) -> String {
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
                return String(
                    format: NSLocalizedString("Someone wrote on %@:",
                                              comment: "Reply to unknown sender with date"),
                    dateFormatter.string(from: rd as Date))
            } else {
                return NSLocalizedString("Someone wrote:",
                                         comment: "Reply to unknown sender without date")
            }
        } else if theNames.count == 1 {
            if let rd = theDate {
                return String(
                    format: NSLocalizedString(
                        "%@ wrote on %@:", comment: "Reply to single contact, with date"),
                    theNames[0], dateFormatter.string(from: rd as Date))
            } else {
                return String(
                    format: NSLocalizedString(
                        "%@ wrote:", comment: "Reply to single contact, without date"),
                    theNames[0])
            }
        } else {
            let allNames = theNames.joined(separator: nameSeparator)
            if let rd = theDate {
                return String(
                    format: NSLocalizedString(
                        "%@ wrote on %@:",
                        comment: "Reply to multiple contacts, with date"),
                    allNames, dateFormatter.string(from: rd as Date))
            } else {
                return String(
                    format: NSLocalizedString(
                        "%@ wrote:", comment: "Reply to multiple contacts, without date"),
                    allNames)
            }
        }
    }

    static private func footer() -> String {
        return NSLocalizedString("Sent with p≡p",
                                 comment: "Message footer/default text")
    }
}
