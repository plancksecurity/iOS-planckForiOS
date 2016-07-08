//
//  Regex.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {
    public func wholeRange() -> NSRange {
        return NSRange.init(location: 0, length: characters.count)
    }

    public func unquote() -> String {
        do {
            let regex = try NSRegularExpression.init(
                pattern: "^\"(.*)\"$", options: [])
            if let match = regex.firstMatchInString(
                self, options: [],
                range: wholeRange()) {
                let r1 = match.rangeAtIndex(1)
                let name = (self as NSString).substringWithRange(r1)
                return name
            }
        } catch let err as NSError {
            Log.errorComponent("unquote", error: err)
        }
        return self
    }

    /**
     Very rudimentary test whether this String is a valid email.
     Basically checks for matches of "a@a", where a is an arbitrary character.
     - Returns: `true` if the number of matches are exactly 1, `false` otherwise.
     */
    public func isProbablyValidEmail() -> Bool {
        do {
            let internalExpression = try NSRegularExpression.init(pattern: ".*\\w+@\\w+.*", options: .CaseInsensitive)
            let matches = internalExpression.matchesInString(self, options: [], range: wholeRange())
            return matches.count == 1
        } catch let err as NSError {
            Log.errorComponent("String", error: err)
            return false
        }
    }

    public func contains(substring: String, ignoreCase: Bool = true,
                         ignoreDiacritic: Bool = true) -> Bool {

        if substring == "" { return true }
        var options = NSStringCompareOptions()

        if ignoreCase { options.unionInPlace(.CaseInsensitiveSearch) }
        if ignoreDiacritic { options.unionInPlace(.DiacriticInsensitiveSearch) }

        return self.rangeOfString(substring, options: options) != nil
    }
}

class Regex {
    let comp = "Regex"
    let internalExpression: NSRegularExpression
    let pattern: String

    init?(pattern: String, options: NSRegularExpressionOptions) {
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

    func test(input: String) -> Bool {
        let matches = self.internalExpression.matchesInString(
            input, options: .ReportProgress,
            range:input.wholeRange())
        return matches.count > 0
    }
}
