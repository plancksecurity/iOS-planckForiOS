//
//  String+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public extension String {

    static let bug1442 = "bug1442"
    static let returnKey = "\n"
    static let space = " "

    static let unquoteRegex = try! NSRegularExpression(pattern: "^\"(.*)\"$", options: [])

    static let namePartOfEmailRegex = try! NSRegularExpression(pattern: "^([^@]+)@", options: [])

    static let endWhiteSpaceRegex = try! NSRegularExpression(pattern: "^(.*?)\\s*$", options: [])

    static let newlineRegex = try! NSRegularExpression(
        pattern: "(\\n|\\r\\n)+", options: [])

    static let threeOrMoreNewlinesRegex = try! NSRegularExpression(pattern: "(\\n|\\r\\n){3,}",
                                                                   options: [])

    static let fileExtensionRegex = try! NSRegularExpression(pattern: "^([^.]+)\\.([^.]+)$",
                                                             options: [])

    /**
     Trims whitespace from back and front.
     */
    public func trimmed() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func contains(find: String) -> Bool {
        return (self.range(of: find, options: .caseInsensitive) != nil)
    }

    public func unquote() -> String {
        if let match = String.unquoteRegex.firstMatch(
                in: self, options: [],
                range: wholeRange()) {
                let r1 = match.range(at: 1)
                let name = (self as NSString).substring(with: r1)
                return name
            }
        return self
    }

    public func trimObjectReplacementCharacters() -> String {
        // UITextView places this character if you delete an attachment, which leads to a
        // non-empty string.
        // https://www.fileformat.info/info/unicode/char/fffc/index.htm
        let objectReplacementCharacter = "\u{FFFC}"

        return self.replacingOccurrences(of: objectReplacementCharacter, with: "")
    }

    /**
     Runs `trimmedWhiteSpace`, `unquote`, and `trimmedWhiteSpace` again.
     */
    public func fullyUnquoted() -> String {
        return trimmed().unquote().trimmed()
    }

    /**
     - Returns: The name part of an email, e.g. "test@blah.com" -> "test"
     */
    public func namePartOfEmail() -> String {
            let matches = String.namePartOfEmailRegex.matches(
                in: self, options: [], range: wholeRange())
            if matches.count == 1 {
                let m = matches[0]
                let r = m.range(at: 1)
                if r.location != NSNotFound {
                    let s = self as NSString
                    let result = s.substring(with: r)
                    return result
                }
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

    /// Replaces all matches of the given regex pattern with a given string.
    ///
    /// - Parameters:
    ///   - pattern: pattern to match
    ///   - replacee: string to raplace matches with
    mutating func replaceRegexMatches(of pattern: String, with replacee: String) {
        do {
            let regex =
                try NSRegularExpression(pattern: pattern,
                                        options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self,
                                                  options: [],
                                                  range: range,
                                                  withTemplate: replacee)
        } catch {
            return
        }
    }

    /// Removes all matches of the given regex pattern.
    ///
    /// - Parameter pattern: regex patterns whichs matches should be removed
    mutating func removeRegexMatches(of pattern: String) {
        replaceRegexMatches(of: pattern, with: "")
    }

    func stringByRemovingRegexMatches(of pattern: String) -> String {
        return self.stringByReplacingRegexMatches(of: pattern, with: "")
    }

    func stringByReplacingRegexMatches(of pattern: String, with replacee: String) -> String {
        var result = self
        do {
            let regex =
                try NSRegularExpression(pattern: pattern,
                                        options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            result = regex.stringByReplacingMatches(in: self,
                                                    options: [],
                                                    range: range,
                                                    withTemplate: replacee)
        } catch {
            Log.shared.errorAndCrash("Catched!")
            return result
        }
        return result
    }

    /**
     Does this String match the given regex pattern? Without any options.
     - Parameter pattern: The pattern to match.
     */
    public func matches(pattern: String) -> Bool {
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
        } catch {
            Log.shared.errorAndCrash("%{public}@", error.localizedDescription)
        }
        return false
    }

    /**
     - Returns: True if this String consists only of whitespace.
     */
    public func isOnlyWhiteSpace() -> Bool {
        let whiteSpacePattern = "^\\s*$"
        return matches(pattern: whiteSpacePattern)
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
                let r = m.range(at: 1)
                if r.location != NSNotFound {
                    let s = self as NSString
                    let result = s.substring(with: r)
                    return result
                }
            }
        } catch {
            Log.shared.errorAndCrash("%{public}@",
                                                        error.localizedDescription)
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
                let r = m.range(at: 1)
                if r.location != NSNotFound {
                    let s = self as NSString
                    let result = s.substring(with: r)
                    return result
                }
            }
        } catch {
            Log.shared.errorAndCrash("%{public}@",
                                                        error.localizedDescription)
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
        return matches(pattern: "^\(prefix)")
    }

    public func hasExtension(_ ext: String) -> Bool {
        let suffix = ext.startsWith(".") ? ext : ".\(ext)"
        return endsWith(suffix)
    }

    public func endsWith(_ suffix: String) -> Bool {
        let suffixCount = suffix.count
        if self.count < suffixCount {
            return false
        }
        let fromWhere = index(endIndex, offsetBy: -suffixCount)
        let end = self[fromWhere...]
        return end == suffix
    }

    public func replaceNewLinesWith(_ delimiter: String) -> String {
        return String.newlineRegex.stringByReplacingMatches(
            in: self, options: [], range: self.wholeRange(), withTemplate: delimiter)
    }

    /**
     - Returns: A new string that never contains 3 or more consecutive newlines.
     */
    public func eliminateExcessiveNewLines() -> String {
        return String.threeOrMoreNewlinesRegex.stringByReplacingMatches(
            in: self, options: [], range: self.wholeRange(), withTemplate: "\n\n")
    }

    public func splitFileExtension() -> (String, String?) {
        if let match = String.fileExtensionRegex.firstMatch(
            in: self, options: [],
            range: wholeRange()) {
            let r1 = match.range(at: 1)
            let name = (self as NSString).substring(with: r1)
            let r2 = match.range(at: 2)
            let ext = (self as NSString).substring(with: r2)
            return (name, ext)
        }
        return (self, nil)
    }

    /**
     Transforms the typical Window/DOS line endings into UNIX ones.
     - Returns: A new string with all newlines being UNIX ones (just "\n").
     */
    public func applyingDos2Unix() -> String {
        return replacingOccurrences(of: "\r\n", with: "\n")
    }

    /**
     Equivalent to the drop functions. Returns a substring that comprises the first maxCount
     characters.
     */
    public func take(maxCount: Int) -> String {
        let theLength = count
        if maxCount >= theLength {
            return self
        } else {
            return String(dropLast(theLength - maxCount))
        }
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

// MARK: - Extensions for drawing initials from users

extension String {
    /**
     - Returns: The first part of a String, with a maximum length of `ofLength`.
     */
    public func prefix(ofLength: Int) -> String {
        if self.count >= ofLength {
            let start = self.startIndex
            return String(prefix(upTo: self.index(start, offsetBy: ofLength)))
        } else {
            return self
        }
    }

    /**
     - Returns: A list of words contained in that String. Primitively separates by
     delimiters like "-", or " ".
     */
    func tokens() -> [String] {
        return self.components(separatedBy: CharacterSet(charactersIn: "- ")).map {
            return $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /**
     - Returns: The initials of the String interpreted as a name,
     that is ideally the first letters of the given name and the last name.
     If that is not possible, improvisations are used.
     */
    public func initials() -> String {
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
    public func draw(centeredIn size: CGSize, color: UIColor, font: UIFont) {
        func center(size: CGSize, inRect: CGRect) -> CGRect {
            let xStart = round(inRect.size.width / 2 - size.width / 2)
            let yStart = round(inRect.size.height / 2 - size.height / 2)
            let o = CGPoint(x: xStart, y: yStart)
            return CGRect(origin: o, size: size)
        }

        let wholeRect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        let nsString = self as NSString
        let textAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.strokeColor: color,
            NSAttributedString.Key.foregroundColor: color,
            NSAttributedString.Key.font: font]
        let stringSize = nsString.size(withAttributes: textAttributes)
        let textRect = center(size: stringSize, inRect: wholeRect)
        nsString.draw(in: textRect, withAttributes: textAttributes)
    }

    /**
     - Returns: A string derived from the self with all spaces removed.
     */
    public func despaced() -> String {
        var newChars = [Character]()

        for ch in self {
            if ch != " " {
                newChars.append(ch)
            }
        }

        return String(newChars)
    }

    public func wholeRange() -> NSRange {
        return NSRange(location: 0, length: count)
    }

}
