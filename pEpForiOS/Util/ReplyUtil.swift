//
//  ReplyUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

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
        let citation = citationHeaderForMessage(message)

        return "\n\n\(footer())\n\n\(citation)\n\n\(quotedText)"
    }

    /// Adds citation header with data of a given message to a given text.
    ///
    /// - Parameters:
    ///   - textToCite: text to cite
    ///   - msg: message to take data (sender, date sent ...) from
    /// - Returns: text with citation header and "send by pEp" footer
    static func citedMessageText(textToCite: String, fromMessage msg: Message) -> String {
        let citation = citationHeaderForMessage(msg)
        return "\n\n\(footer())\n\n\(citation)\n\n\(citedTextWithNewLines(textToCite: textToCite))"
    }

    static func citedTextWithNewLines(textToCite: String) -> String {
        let quoteChar = ">"
        var citedText = ""
        for line in textToCite.components(separatedBy: "\n") {
            citedText = citedText + quoteChar + " " + line + "\n"
        }
        return citedText.trimmingCharacters(in: .newlines)
    }

    /// Adds citation header with data of a given message to a given text.
    ///
    /// - Parameters:
    ///   - textToCite: text to cite
    ///   - msg: message to take data (sender, date sent ...) from
    /// - Returns: text with citation header and "send by pEp" footer
    public static func citedMessageText(textToCite: NSAttributedString,
                                        fromMessage msg: Message) -> NSAttributedString {
        let citation = citationHeaderForMessage(msg)

        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        var result = NSAttributedString(string: "\n\n\(footer())\n\n\(citation)\n\n",
            attributes: [NSAttributedString.Key(rawValue: "NSFont"): defaultFont])
        let quoteChar = ">"
        result = result + quoteChar + " " + textToCite
        return result
    }

    /**
     Gets the subject for replying to the given `Message`.
     */
    public static func replySubject(message: Message) -> String {
        // The one and only reply RFC-defined prefix for replies,
        // see https://tools.ietf.org/html/rfc5322#section-3.6.5
        let replyPrefix = "Re: "

        if var theSubject = message.shortMessage {
            theSubject = theSubject.trimmed()
            // remove all old prefixed `replyPrefix`es
            while theSubject.hasPrefix(replyPrefix) {
                theSubject = String(theSubject[replyPrefix.endIndex..<theSubject.endIndex])
                theSubject = theSubject.trimmed()
            }

            return "\(replyPrefix)\(theSubject)"
        }

        return replyPrefix
    }

    public static func forwardSubject(message: Message) -> String {
        let replyPrefix = "Fwd: "

        if var theSubject = message.shortMessage {
            theSubject = theSubject.trimmed()
            while theSubject.hasPrefix(replyPrefix) {
                theSubject = String(theSubject[replyPrefix.endIndex..<theSubject.endIndex])
                theSubject = theSubject.trimmed()
            }

            return "\(replyPrefix)\(theSubject)"
        }
        return replyPrefix
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
        return citedTextWithNewLines(textToCite: text)
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
        textToQuote = formatted.extractTextFromHTML(respectNewLines: true)

        return textToQuote //message.longMessage
    }

    static private func replyNameFromIdentity(_ identity: Identity) -> String {
        if let name = identity.userName {
            return name
        }
        return identity.address
    }

    static private func citationHeaderForMessage(_ message: Message) -> String {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateStyle = DateFormatter.Style.long
        dateFormatter.timeStyle = DateFormatter.Style.long

        let theDate = message.sent

        var theNames = [String]()
        if let from = message.from {
            theNames.append(replyNameFromIdentity(from))
        }

        if theNames.isEmpty {
            if let rd = theDate {
                return String.localizedStringWithFormat(
                    NSLocalizedString("Someone wrote on %1$@:",
                                      comment: "Reply to unknown sender with date"),
                    dateFormatter.string(from: rd as Date))
            } else {
                return NSLocalizedString("Someone wrote:",
                                         comment: "Reply to unknown sender without date")
            }
        } else {
            if let rd = theDate {
                return String.localizedStringWithFormat(
                    NSLocalizedString(
                        "%1$@ wrote on %2$@:",
                        comment: "Reply to single contact, with date. Placeholders: Name, date."),
                    theNames[0], dateFormatter.string(from: rd as Date))
            } else {
                return String.localizedStringWithFormat(
                    NSLocalizedString(
                        "%1$@ wrote:",
                        comment: "Reply to single contact, without date. Placeholder: Name."),
                    theNames[0])
            }
        }
    }

    static private func footer() -> String {
        return String.pepSignature
    }
}
