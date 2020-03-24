//
//  NSAttributedString+Parsing.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

public protocol NSAttributedStringParsingDelegate: class {
    func stringFor(attachment: NSTextAttachment) -> String?
}

public extension NSAttributedString {
    func convert(delegate: NSAttributedStringParsingDelegate) -> String {
        var resultString = ""
        let string = NSMutableAttributedString(attributedString: self)
        string.fixAttributes(in: string.wholeRange())

        string.enumerateAttributes(in: string.wholeRange(), options: []) { attrs, r, stop in
            if let attachment = attrs[NSAttributedString.Key(rawValue:"NSAttachment")] as? NSTextAttachment {
                if let attachmentString = delegate.stringFor(attachment: attachment) {
                    resultString = "\(resultString)\(attachmentString)"
                }
            } else {
                let theAttributedString = string.attributedSubstring(from: r)
                let theString = theAttributedString.string
                resultString = "\(resultString)\(theString)"
            }
        }
        return resultString
    }

    func toCitation(addCitationLevel: Bool = false) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: self)
        let mutableAttributedString = NSMutableAttributedString(string: "")

        var ranges: [Int: (range: NSRange, level: Int)] = [:]
        var blockquoteLevels = 0
        var indexForStartLine = 0


        for line in attributedString.mutableString.components(separatedBy: .newlines) {
            blockquoteLevels = blockquoteLevels + blockquoteLevel(text: line)
            var toAdd = ""
            for _ in 0..<blockquoteLevels {
                toAdd += ">"
            }
            let range = attributedString.mutableString.range(of: line, options: .literal)
            if range.location == NSNotFound {
                continue
            }
            mutableAttributedString.append(NSAttributedString(string: toAdd + " ") + self.attributedSubstring(from: range) + NSAttributedString(string: "\n"))
            ranges[indexForStartLine] = (range: NSRange(location: indexForStartLine,
                                                        length: line.count),
                                         level: blockquoteLevels)
            indexForStartLine += line.count
        }

//        for line in self.string.components(separatedBy: .newlines) {
//            blockquoteLevels = blockquoteLevels + blockquoteLevel(text: line)
//            var toAdd = ""
//            for _ in 0..<blockquoteLevels {
//                toAdd += ">"
//            }
//            attributedString.append(NSAttributedString(string: toAdd + " " + line + "\n"))
//            print("DEV: line: [\(blockquoteLevels)] \(toAdd) \(line)")
//            ranges[indexForStartLine] = (range: NSRange(location: indexForStartLine,
//                                                        length: line.count),
//                                         level: blockquoteLevels)
//            indexForStartLine += line.count
//        }

        let verticalLine = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.backgroundColor : UIColor.pEpGreen])
        let spaceForVerticalLine = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.backgroundColor : UIColor.clear])

        return mutableAttributedString
            .replacingOccurrences(ofWith: [">" : verticalLine + spaceForVerticalLine + spaceForVerticalLine])
            .replacingOccurrences(ofWith: ["› " : "", "›" : "", "‹ " : "", "‹" : "", " ›" : "", " ‹" : ""])
    }

    private func blockquoteLevel(text: String) -> Int {
        var level = 0

        for char in text {
            switch char {
            case "›":
                level += 1
            case "‹":
                level -= 1
            case " ":
                break
            default:
                return level
            }
        }

        return level
    }

    func replacingOccurrences<T>(ofWith: [String: T]) -> NSAttributedString {

        let attributedString = NSMutableAttributedString(attributedString: self)
        let charsToReplace = Array(ofWith.keys)

        for charToReplace in charsToReplace {
            while attributedString.mutableString.contains(charToReplace) {
                let range = attributedString.mutableString.range(of: charToReplace)
                guard range.lowerBound != NSNotFound else {
                    // early quit, nothing to do and also avoid an endless loop
                    break
                }
                if let value = ofWith[charToReplace] as? String {
                    attributedString.replaceCharacters(in: range, with: value)
                }
                if let value = ofWith[charToReplace] as? NSAttributedString {
                    attributedString.replaceCharacters(in: range, with: value)
                }
            }
        }

        return NSAttributedString(attributedString: attributedString)
    }

    func rangeOf(string: String) -> Range<String.Index>? {
        return self.string.range(of: string)
    }
}
