//
//  String+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public extension String {
    static let internalRecipientDelimiter = ","
    static let externalRecipientDelimiter = ", "
    static let returnKey = "\n"
    static let comp = "String.Extensions"
    
    public var trim: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var isEmailAddress: Bool {
        let eav = EmailAddressValidation(address: self)
        return eav.result
    }
    
    public func contains(find: String) -> Bool {
        return (self.range(of: find, options: .caseInsensitive) != nil)
    }

    public func unquote() -> String {
        do {
            let regex = try NSRegularExpression(
                pattern: "^\"(.*)\"$", options: [])
            if let match = regex.firstMatch(
                in: self, options: [],
                range: wholeRange()) {
                let r1 = match.rangeAt(1)
                let name = (self as NSString).substring(with: r1)
                return name
            }
        } catch let err as NSError {
            Log.error(component: "unquote", error: err)
        }
        return self
    }

    /**
     Runs `trimmedWhiteSpace`, `unquote`, and `trimmedWhiteSpace` again.
     */
    public func fullyUnquoted() -> String {
        return trimmedWhiteSpace().unquote().trimmedWhiteSpace()
    }

    /**
     Very rudimentary test whether this String is a valid email.
     - Returns: `true` if the number of matches are exactly 1, `false` otherwise.
     */
    public func isProbablyValidEmail() -> Bool {
        do {
            let internalExpression = try NSRegularExpression(
                pattern: "^[^@,]+@[^@,]+$", options: .caseInsensitive)
            let matches = internalExpression.matches(in: self, options: [], range: wholeRange())
            return matches.count == 1
        } catch let err as NSError {
            Log.error(component: "String", error: err)
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
            let regex = try NSRegularExpression(pattern: "^([^@]+)@", options: [])
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
            Log.error(component: String.comp, error: err)
        }
        return self.replacingOccurrences(of: "@", with: "_")
    }

    public func containsString(_ substring: String, ignoreCase: Bool = true,
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
        var comps = self.components(separatedBy: String.internalRecipientDelimiter)
        if comps.count == 1 {
            return ""
        } else {
            comps = Array(comps.dropLast())
            let ar = comps.map({$0.trimmedWhiteSpace()})
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
            let regex = try NSRegularExpression(pattern: "^(.*?)\\s*$",
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
            Log.error(component: String.comp, error: err)
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
            let regex = try NSRegularExpression(pattern: pattern, options: reOptions)
            let matches = regex.matches(in: self, options: [], range: wholeRange())
            return matches.count > 0
        } catch let err as NSError {
            Log.error(component: String.comp, error: err)
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
            let regex = try NSRegularExpression(pattern: "(.*?)\(pattern)$", options: [])
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
            Log.error(component: String.comp, error: err)
        }
        return self
    }

    /**
     Removes a matching pattern from the beginning of the String. Note that the '^' will be added
     by this method.
     */
    public func removeLeadingPattern(_ pattern: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: "^\(pattern)(.*?)$", options: [])
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
            Log.error(component: String.comp, error: err)
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

    public func hasExtension(_ ext: String) -> Bool {
        let suffix = ext.startsWith(".") ? ext : ".\(ext)"
        return endsWith(suffix)
    }

    public func endsWith(_ suffix: String) -> Bool {
        let suffixCount = suffix.characters.count
        if characters.count < suffixCount {
            return false
        }
        let fromWhere = index(endIndex, offsetBy: -suffixCount)
        let end = substring(from: fromWhere)
        return end == suffix
    }

    public func replaceNewLinesWith(_ delimiter: String) -> String {
        do {
            let regex = try NSRegularExpression(
                pattern: "(\\n|\\r\\n)+", options: [])
            return regex.stringByReplacingMatches(
                in: self, options: [], range: self.wholeRange(), withTemplate: delimiter)
        } catch let err as NSError {
            Log.error(component: #function, error: err)
            return self
        }
    }

    /**
     - Returns: A new string that never contains 3 or more consecutive newlines.
     */
    public func eliminateExcessiveNewLines() -> String {
        do {
            let regex = try NSRegularExpression(
                pattern: "(\\n|\\r\\n){3,}", options: [])
            return regex.stringByReplacingMatches(
                in: self, options: [], range: self.wholeRange(), withTemplate: "\n\n")
        } catch let err as NSError {
            Log.error(component: #function, error: err)
            return self
        }
    }

    public func splitFileExtension() -> (String, String?) {
        do {
            let regex = try NSRegularExpression(
                pattern: "^([^.]+)\\.([^.]+)$", options: [])
            if let match = regex.firstMatch(
                in: self, options: [],
                range: wholeRange()) {
                let r1 = match.rangeAt(1)
                let name = (self as NSString).substring(with: r1)
                let r2 = match.rangeAt(2)
                let ext = (self as NSString).substring(with: r2)
                return (name, ext)
            }
        } catch let err as NSError {
            Log.error(component: #function, error: err)
        }
        return (self, nil)
    }
}

public extension NSAttributedString {
    
    public func wholeRange() -> NSRange {
        return NSRange(location: 0, length: length)
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
            try internalExpression = NSRegularExpression(
                pattern: pattern, options: options)
        } catch let err as NSError {
            Log.error(component: comp, error: err)
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

// MARK: - Extensions for drawing initials from users

extension String {
    /**
     - Returns: The first part of a String, with a maximum length of `ofLength`.
     */
    func prefix(ofLength: Int) -> String {
        if self.characters.count >= ofLength {
            let start = self.startIndex
            return self.substring(to: self.index(start, offsetBy: ofLength))
        } else {
            return self
        }
    }

    /**
     - Returns: A list of words contained in that String. Might parse parentheses
     in the future, at the moment just separates by space.
     */
    func tokens() -> [String] {
        return self.characters.split(separator: " ").map(String.init).map() {
            return $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /**
     - Returns: The initials of the String interpreted as a name,
     that is ideally the first letters of the given name and the last name.
     If that is not possible, improvisations are used.
     */
    func initials() -> String {
        let words = tokens()
        if words.count == 0 {
            return "?"
        }
        if words.count == 1 {
            return self.prefix(ofLength: 2)
        }
        let word1 = words[0]
        let word2 = words[words.count - 1]
        return "\(word1.prefix(ofLength: 1).capitalized)\(word2.prefix(ofLength: 1).capitalized)"
    }

    /**
     Draws `text` in the current context in the given `color`, centered in a rectangle with
     size `size`.
     */
    func draw(centeredIn size: CGSize, color: UIColor, font: UIFont) {
        func center(size: CGSize, inRect: CGRect) -> CGRect {
            let xStart = round(inRect.size.width / 2 - size.width / 2)
            let yStart = round(inRect.size.height / 2 - size.height / 2)
            let o = CGPoint(x: xStart, y: yStart)
            return CGRect(origin: o, size: size)
        }

        let wholeRect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        let nsString = self as NSString
        let textAttributes: [String : Any] = [
            NSStrokeColorAttributeName: color,
            NSForegroundColorAttributeName: color,
            NSFontAttributeName: font]
        let stringSize = nsString.size(attributes: textAttributes)
        let textRect = center(size: stringSize, inRect: wholeRect)
        nsString.draw(in: textRect, withAttributes: textAttributes)
    }
}
