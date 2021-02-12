//
//  String+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

extension String {

   static let bug1442 = "bug1442"
   static public let returnKey = "\n"
   static public let space = " "

   static let unquoteRegex = try! NSRegularExpression(pattern: "^\"(.*)\"$", options: [])
   static let endWhiteSpaceRegex = try! NSRegularExpression(pattern: "^(.*?)\\s*$", options: [])
   static let newlineRegex = try! NSRegularExpression(pattern: "(\\n|\\r\\n)+", options: [])
   static let threeOrMoreNewlinesRegex = try! NSRegularExpression(pattern: "(\\n|\\r\\n){3,}", options: [])
   static let fileExtensionRegex = try! NSRegularExpression(pattern: "^(.+?)\\.([^.]+)$", options: [])
   static let emailRegex = try! NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", options: [])

   private var firstLetterCapitalized: String {
       if count > 0 {
           return prefix(ofLength: 1).capitalized
       }
       return ""
   }

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
           let range = NSMakeRange(0, count)
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
   mutating public func removeRegexMatches(of pattern: String) {
       replaceRegexMatches(of: pattern, with: "")
   }

   public func stringByRemovingRegexMatches(of pattern: String) -> String {
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

   /// Find substrings for given pattern
   /// - Parameter pattern: regex pattern
   public func find(pattern: String) -> [String] {
       do {
           let regex = try NSRegularExpression(pattern: pattern)
           let string = NSString(string: self)
           let results = regex.matches(in: self, range: NSMakeRange(0, string.length))
           return results.map { string.substring(with: $0.range) }
       } catch let error {
           print("Error, maybe invalid regex: " + error.localizedDescription)
       }
       return []
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
           Log.shared.errorAndCrash(error: error)
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
           Log.shared.errorAndCrash(error: error)
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
           Log.shared.errorAndCrash(error: error)
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

   /// it's true when the string only contains digits
   public var isDigits: Bool {
       let digits = CharacterSet.decimalDigits
       return unicodeScalars.allSatisfy { digits.contains($0) }
   }

   /// it's true when the string only contains letters
   public var isLetter: Bool {
       let letters = CharacterSet.letters
       return unicodeScalars.allSatisfy { letters.contains($0) }
   }

   /// it's true when the string is only a backspace
   public var isBackspace: Bool {
       var backspace = CharacterSet()
       backspace.insert(Unicode.Scalar("\u{0008}"))
       return unicodeScalars.allSatisfy { backspace.contains($0) }
   }

   /// Returns the string with all characters removed that are not alpha-numeric.
   ///
   /// - Returns: string with non-alpha-numeric stripped.
   public func alphaNumericOnly() -> String {
       var alphaNumeric = CharacterSet()
       alphaNumeric.formUnion(CharacterSet.letters)
       alphaNumeric.formUnion(CharacterSet.decimalDigits)
       return self.string(everythingStrippedThatIsNotInCharset: alphaNumeric)
   }

   /// Returns the string with all characters removed that are in thegiven charset.
   ///
   /// - Returns: string with all chars stripped that are not in the given charset
   public func string(everythingStrippedThatIsNotInCharset charset: CharacterSet) -> String {
       return String(self.unicodeScalars.filter { charset.contains($0) })
   }
}

extension NSAttributedString {

   public func wholeRange() -> NSRange {
       return NSRange(location: 0, length: length)
   }
}

extension Character {
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
       if count >= ofLength {
           let start = startIndex
           return String(prefix(upTo: index(start, offsetBy: ofLength)))
       }
       return self
   }

   /**
    - Returns: A list of words contained in that String. Primitively separates by
    delimiters like "-", or " ".
    */
   fileprivate func tokens() -> [String] {
       let pattern = "[^A-Za-z0-9]"
       return components(separatedBy: CharacterSet(charactersIn: "- ")).map {
           return $0.trimmingCharacters(in: .whitespacesAndNewlines)
       }.map { $0.replacingOccurrences(of: pattern, with: "", options: [.regularExpression]) }
   }

   /// - Returns: the initials of the String interpreted as a name.
   /// that is ideally the first letters of the given name and lastname.
   /// If it only has one word (name or lastname) that will be taken to get the initial.
   /// If not possible, returns nil.
   public func initials() -> String? {
       var words = tokens()
       // Remove emails
       words = words.filter { !String.emailRegex.matchesWhole(string: $0) }
       //Non words, no initials
       if words.count == 0 {
           return nil
       }

       //One word, take the first letter
       let word1 = words[0]
       if words.count == 1 {
           return word1.firstLetterCapitalized
       }

       //More than one word, take the initials of the first and the last words
       let word2 = words[words.count - 1]
       return "\(word1.firstLetterCapitalized)\(word2.firstLetterCapitalized)"
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
