//
//  Regex.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

extension String {
    func wholeRange() -> NSRange {
        return NSRange.init(location: 0, length: characters.count)
    }

    func unquote() -> String {
        do {
            let regex = try NSRegularExpression.init(
                pattern: "^\\s*\"(.+)\"\\s*$", options: [])
            if let match = regex.firstMatchInString(
                self, options: [],
                range: wholeRange()) {
                let r1 = match.rangeAtIndex(1)
                let name = (self as NSString).substringWithRange(r1)
                return name
            }
        } catch let err as NSError {
            Log.error("unquote", error: err)
        }
        return self
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
            Log.error(comp, error: err)
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
