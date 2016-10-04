//
//  StringExtensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public extension String {
    static let internalRecipientDelimiter = ","
    static let externalRecipientDelimiter = ", "
    static let comp = "String.Extensions"

    public func wholeRange() -> NSRange {
        return NSRange.init(location: 0, length: characters.count)
    }

    public func unquote() -> String {
        do {
            let regex = try NSRegularExpression.init(
                pattern: "^\"(.*)\"$", options: [])
            if let match = regex.firstMatch(
                in: self, options: [],
                range: wholeRange()) {
                let r1 = match.rangeAt(1)
                let name = (self as NSString).substring(with: r1)
                return name
            }
        } catch let err as NSError {
            Log.errorComponent("unquote", error: err)
        }
        return self
    }

    /**
     Very rudimentary test whether this String is a valid email.
     - Returns: `true` if the number of matches are exactly 1, `false` otherwise.
     */
    public func isProbablyValidEmail() -> Bool {
        do {
            let internalExpression = try NSRegularExpression.init(
                pattern: "^[^@,]+@[^@,]+$", options: .caseInsensitive)
            let matches = internalExpression.matches(in: self, options: [], range: wholeRange())
            return matches.count == 1
        } catch let err as NSError {
            Log.errorComponent("String", error: err)
            return false
        }
    }

    /**
     Contains a String like e.g. "email1, email2, email3", only probably valid emails?
     - Parameter delimiter: The delimiter that separates the emails.
     - Returns: True if all email parts yield true with `isProbablyValidEmail`.
     */
    public func isProbablyValidEmailListSeparatedBy(_ delimiter: String = ",") -> Bool {
        let emails = self.components(separatedBy: delimiter).map({
            $0.trimmedWhiteSpace()
        })
        for e in emails {
            if e.matchesPattern("\(delimiter)") || !e.isProbablyValidEmail() {
                return false
            }
        }
        return true
    }

    /**
     - Returns: The name part of an email, e.g. "test@blah.com" -> "test"
     */
    public func namePartOfEmail() -> String {
        do {
            let regex = try NSRegularExpression.init(pattern: "^([^@]+)@", options: [])
            let matches = regex.matches(in: self, options: [], range: wholeRange())
            if matches.count == 1 {
                let m = matches[0]
                let r = m.rangeAt(1)
                if r.location != NSNotFound {
                    let s = self as NSString
                    let result = s.substring(with: r)
                    return result
                }
            }
        } catch let err as NSError {
            Log.errorComponent(String.comp, error: err)
        }
        return self.replacingOccurrences(of: "@", with: "_")
    }

    public func contains(_ substring: String, ignoreCase: Bool = true,
                         ignoreDiacritic: Bool = true) -> Bool {

        if substring == "" {
            return true
        }

        var options = NSString.CompareOptions()

        if ignoreCase { options.formUnion(.caseInsensitive) }
        if ignoreDiacritic { options.formUnion(.diacriticInsensitive) }

        return self.range(of: substring, options: options) != nil
    }

    /**
     Mimicks the `NSString` version.
     */
    public func stringByReplacingCharactersInRange(_ range: NSRange,
                                                   withString replacement: String) -> String {
        let s = self as NSString
        return s.replacingCharacters(in: range, with: replacement)
    }

    /**
     Assumes that the `String` is a list of recipients, delimited by comma (","), and you
     can only edit the last one. This is very similar to the way the native iOS mail app
     handles contact input.
     - Returns: The last part of a contact list that can still be edited.
     */
    public func unfinishedRecipientPart() -> String {
        let comps = self.components(separatedBy: String.internalRecipientDelimiter)
        if comps.count == 0 {
            return self
        } else {
            return comps.last!.trimmedWhiteSpace()
        }
    }

    /**
     - Returns: The part of a recipient list that connot be edited anymore.
     */
    public func finishedRecipientPart() -> String {
        let comps = self.components(separatedBy: String.internalRecipientDelimiter)
        if comps.count == 1 {
            return ""
        } else {
            let ar = comps[0..<comps.count-1].map({$0.trimmedWhiteSpace()})
            return ar.joined(separator: String.externalRecipientDelimiter)
        }
    }

    /**
     Trims whitespace from back and front.
     */
    public func trimmedWhiteSpace() -> String {
        enum ScanState {
            case start
            case middle
            case end
        }

        var state = ScanState.start
        var result = ""

        // With a regex there are problems with "\r\n" at the beginning of the String,
        // so solve that part manually.
        for ch in characters {
            if state == .start {
                if !ch.isWhitespace() {
                    state = .middle
                    result.append(ch)
                }
            } else {
                result.append(ch)
            }
        }

        do {
            let regex = try NSRegularExpression.init(pattern: "^(.*?)\\s*$",
                                                     options: [])
            let matches = regex.matches(in: result, options: [], range: result.wholeRange())
            if matches.count > 0 {
                let m = matches[0]
                let r = m.rangeAt(1)
                if r.location != NSNotFound {
                    let s = result as NSString
                    let result = s.substring(with: r)
                    return result
                }
            }
        }
        catch let err as NSError {
            Log.errorComponent(String.comp, error: err)
        }
        return result
    }

    /**
     Does this String match the given regex pattern? Without any options.
     - Parameter pattern: The pattern to match.
     */
    public func matchesPattern(_ pattern: String) -> Bool {
        return matchesPattern(pattern, reOptions: [])
    }

    /**
     Does this String match the given regex pattern?
     - Parameter pattern: The pattern to match.
     - Parameter reOptions: Options given to the regular expression init.
     */
    public func matchesPattern(
        _ pattern: String, reOptions: NSRegularExpression.Options) -> Bool {
        do {
            let regex = try NSRegularExpression.init(pattern: pattern, options: reOptions)
            let matches = regex.matches(in: self, options: [], range: wholeRange())
            return matches.count > 0
        } catch let err as NSError {
            Log.errorComponent(String.comp, error: err)
        }
        return false
    }

    /**
     - Returns: True if this String consists only of whitespace.
     */
    public func isOnlyWhiteSpace() -> Bool {
        let whiteSpacePattern = "^\\s*$"
        return matchesPattern(whiteSpacePattern)
    }

    /**
     Removes a matching pattern from the end of the String. Note that the '$' will be added
     by this method.
     */
    public func removeTrailingPattern(_ pattern: String) -> String {
        do {
            let regex = try NSRegularExpression.init(pattern: "(.*?)\(pattern)$", options: [])
            let matches = regex.matches(in: self, options: [], range: wholeRange())
            if matches.count == 1 {
                let m = matches[0]
                let r = m.rangeAt(1)
                if r.location != NSNotFound {
                    let s = self as NSString
                    let result = s.substring(with: r)
                    return result
                }
            }
        } catch let err as NSError {
            Log.errorComponent(String.comp, error: err)
        }
        return self
    }

    /**
     Removes a matching pattern from the beginning of the String. Note that the '^' will be added
     by this method.
     */
    public func removeLeadingPattern(_ pattern: String) -> String {
        do {
            let regex = try NSRegularExpression.init(pattern: "^\(pattern)(.*?)$", options: [])
            let matches = regex.matches(in: self, options: [], range: wholeRange())
            if matches.count == 1 {
                let m = matches[0]
                let r = m.rangeAt(1)
                if r.location != NSNotFound {
                    let s = self as NSString
                    let result = s.substring(with: r)
                    return result
                }
            }
        } catch let err as NSError {
            Log.errorComponent(String.comp, error: err)
        }
        return self
    }

    /**
    - Returns: The given string or "" (the empty `String`) if that `String` is nil.
     */
    public static func orEmpty(_ string: String?) -> String {
        if let s = string {
            return s
        }
        return ""
    }

    /**
     - Returns: True if the given string starts with the given prefix.
     */
    public func startsWith(_ prefix: String) -> Bool {
        return matchesPattern("^\(prefix)")
    }

    /**
     Removes "<" from the start, and ">" from the end. Useful for cleaning
     up message IDs if you really need that.
     */
    public func removeAngleBrackets() -> String {
        do {
            let regex = try NSRegularExpression.init(
                pattern: "^\\s*<(.*)>\\s*$", options: [])
            if let match = regex.firstMatch(
                in: self, options: [],
                range: wholeRange()) {
                let r1 = match.rangeAt(1)
                let name = (self as NSString).substring(with: r1)
                return name
            }
        } catch let err as NSError {
            Log.errorComponent("removeAngleBrackets", error: err)
        }
        return self
    }

    /**
     Text from HTML, useful for creating snippets of a mail.
     */
    public func extractTextFromHTML() -> String {
        let htmlData = data(using: String.Encoding.utf8)
        let doc = TFHpple.init(data: htmlData, encoding: "UTF-8", isXML: false)
        let elms = doc?.search(withXPathQuery: "//body//text()[normalize-space()]")

        var result = ""
        for tmp in elms! {
            if let e = tmp as? TFHppleElement {
                let s = e.content.trimmedWhiteSpace()
                if !s.isEmpty {
                    if result.characters.count > 0 {
                        result.append(" " as Character)
                    }
                    result.append(s)
                }
            }
        }
        return result
    }

    public func replaceNewLinesWith(_ delimiter: String) -> String {
        var result = ""

        for ch in characters {
            if !ch.isNewline() {
                result.append(ch)
            } else {
                result.append(delimiter)
            }
        }
        return result
    }
}

public extension NSAttributedString {
    public func wholeRange() -> NSRange {
        return NSRange.init(location: 0, length: length)
    }
}

public extension Character {
    public func isWhitespace() -> Bool {
        switch self {
        case " ", "\t", "\n", "\r", "\r\n":
            return true
        default:
            return false
        }
    }

    public func isNewline() -> Bool {
        switch self {
        case "\n", "\r", "\r\n":
            return true
        default:
            return false
        }
    }
}

class Regex {
    let comp = "Regex"
    let internalExpression: NSRegularExpression
    let pattern: String

    init?(pattern: String, options: NSRegularExpression.Options) {
        self.pattern = pattern
        do {
            try internalExpression = NSRegularExpression.init(
                pattern: pattern, options: options)
        } catch let err as NSError {
            Log.errorComponent(comp, error: err)
            return nil
        }
    }

    convenience init?(_ pattern: String) {
        self.init(pattern: pattern, options: [])
    }

    func test(_ input: String) -> Bool {
        let matches = self.internalExpression.matches(
            in: input, options: .reportProgress,
            range:input.wholeRange())
        return matches.count > 0
    }
}
