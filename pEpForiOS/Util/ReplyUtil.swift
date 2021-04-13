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

    /**
     Gets the quoted message body for the given `Message`.
     */
    public static func quotedMessageText(message: Message, replyAll: Bool) -> NSAttributedString {
        let footerPlainText = footer(for: message)

        guard let quotedText = quotedText(for: message) else {
            return "\n\n\(footerPlainText)".attributedString()
        }
        let citationPlainText = citationHeaderForMessage(message)
        
        return "\n\n".attributedString()
            + footer(for: message).attributedString()
            + "\n\n"
            + citationPlainText.attributedString()
            + "\n\n"
            + quotedText
    }

    /// Adds citation header with data of a given message to a given text.
    ///
    /// - Parameters:
    ///   - textToCite: text to cite
    ///   - msg: message to take data (sender, date sent ...) from
    /// - Returns: text with citation header and "send by pEp" footer
    static func citedMessageText(textToCite: String, fromMessage msg: Message) -> String {
        let citation = citationHeaderForMessage(msg)
        return "\n\n\(footer(for: msg))\n\n\(citation)\n\n\(citedTextWithNewLines(textToCite: textToCite))"
    }

    public static func citedTextWithNewLines(textToCite: String) -> String {
        let quoteChar = ">"
        var citedText = ""
        for line in textToCite.components(separatedBy: "\n") {
            citedText = citedText + quoteChar + " " + line + "\n"
        }
        return citedText.trimmingCharacters(in: .newlines)
    }

    /// Show vertical line for cited messages (only in presentation layer)
    /// - Parameter html: html to inject vertical lines to
    /// - returns: html with vertical lines injected.
    public static func htmlWithVerticalLinesForBlockQuotesInjected(html: String) -> String {
        let searchTerm = "<blockquote type=\"cite\""
        let replace = "<blockquote type=\"cite\" style=\"border-left: 3px solid \(UIColor.pEpGreenHex); padding-left: 8px; margin-left:0px;\""
        return html
            .replacingOccurrences(of: searchTerm,
                                  with: replace)
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
        let result = NSAttributedString(string: "\n\n\(footer(for: msg))\n\n\(citation)\n\n",
            attributes: [NSAttributedString.Key(rawValue: "NSFont"): defaultFont])

        return result + textToCite.toCitation(addCitationLevel: true)
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

        return ""
    }

    public static func forwardSubject(message: Message) -> String {
        if let subject = message.shortMessage {
            let fwd = "Fwd: "
            return String(fwd + subject.trimmed())
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
    static private func quotedText(for message: Message) -> NSAttributedString? {
        guard let text = extractMessageTextToQuote(from: message) else {
            return nil
        }
        return text.toCitation(addCitationLevel: true)
    }

    /// Extracts the text that should be used for quoting (in reply/forwarding) from a given message.
    ///
    /// - Parameter message: message to extract text from
    /// - Returns:  If longMessageFormatted exists: formatted message with HTML tags are striped
    ///             else if longMessage exists: longMessage
    ///             nil otherwize
    static private func extractMessageTextToQuote(from message: Message) -> NSAttributedString? {
        let textToQuote = message.longMessage ?? nil
        guard let formatted = message.longMessageFormatted else {
            return NSAttributedString.normalAttributedString(from: textToQuote ?? "")
        }
        return formatted.htmlToAttributedString(deleteInlinePictures: true,
                                                attachmentDelegate: nil)
    }

    static private func replyNameFromIdentity(_ identity: Identity) -> String {
        if let name = identity.userName {
            return name
        }
        return identity.address
    }

    static public func citationHeaderForMessage(_ message: Message) -> String {
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

    static private func footer(for message: Message) -> String {
        return message.parent.account.signature
    }
}
