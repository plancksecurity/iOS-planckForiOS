//
//  HtmlConversions.swift
//  pEpIOSToolbox
//
//  Created by Adam Kowalski on 25/03/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation
import UIKit

/// Conversions between Html -> NSAttributedString
/// and NSAttributedString -> Html
/// with <blockquote> tags and keep and display quotation levels
/// Quotation levels can be display as ">" grather than char or
/// tricks for display pretty vertical lines instead of ">" grather than mark
public class HtmlConversions {

    private static let verticalLine = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.backgroundColor : UIColor.pEpGreen])
    private static let spaceForVerticalLine = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.backgroundColor : UIColor.clear])

    public init() { }

    public func citedTextGratherThanChars(attribText: NSAttributedString,
                                          addCitationLevel: Bool = false,
                                          specialChar: String = "　") -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: attribText)
        let mutableAttributedString = NSMutableAttributedString(string: "")

        var ranges: [Int: (range: NSRange, level: Int)] = [:]
        var blockquoteLevels = addCitationLevel ? 1 : 0
        var indexForStartLine = 0

        var inlineAttachmentRanges = inlineAttachmentRange(attributedString: attributedString)

        for line in attributedString.mutableString.components(separatedBy: .newlines) {
            let difference = blockquoteLevel(text: line)
            blockquoteLevels += difference
            var toAdd = ""
            if blockquoteLevels > 0 {
                for _ in 0..<blockquoteLevels {
                    toAdd += specialChar
                }
            }
            var range = attributedString.mutableString.range(of: line, options: [])
            if line.isAttachment && !inlineAttachmentRanges.isEmpty {
                range = inlineAttachmentRanges.first
                    ?? NSRange(location: NSNotFound, length: 0)
                inlineAttachmentRanges.removeFirst()
            }

            if range.location == NSNotFound {
                continue
            }
            let subString = attribText.attributedSubstring(from: range)
            mutableAttributedString.append(NSAttributedString(string: toAdd + " ") + subString + NSAttributedString(string: "\n"))
            ranges[indexForStartLine] = (range: NSRange(location: indexForStartLine,
                                                        length: line.count),
                                         level: blockquoteLevels)

            blockquoteLevels -= line.filter { $0 == "‹" }.count + difference - line.filter { $0 == "›" }.count

            indexForStartLine += line.count
        }

        return citationRemoveSpecialChars(attribText: NSAttributedString(attributedString: mutableAttributedString))
    }

    public func citationGraterThanToVerticalLines(attribText: NSAttributedString) -> NSAttributedString {

        return attribText
            .replacingOccurrences(ofWith: ["　" : HtmlConversions.verticalLine + HtmlConversions.spaceForVerticalLine])
    }

    public func citationRemoveSpecialChars(attribText: NSAttributedString) -> NSAttributedString {
        return attribText.replacingOccurrences(ofWith: ["› " : "",
                                                        "›" : "",
                                                        " ‹ " : "",
                                                        " ›" : "",
                                                        "‹ " : "",
                                                        "‹" : ""])
    }

    public func citationVerticalLineToBlockquote(_ aString: NSAttributedString) -> (plainText: String, attribString: NSAttributedString) {

        let mutattribstring = NSMutableAttributedString(attributedString: aString.replacingOccurrences(ofWith: [" " : "Ψ",
                                                                                                                " " : ""]))
        let plainText = mutattribstring.string.replacingOccurrences(of: "Ψ", with: ">")
        let mutableAttribString = NSMutableAttributedString(string: "")

        let lines: [String] = mutattribstring.mutableString.components(separatedBy: .newlines)

        var previousLevel = 0

        for i in 0..<lines.count {
            let levels: Int = lines[i].filter { $0 == "Ψ" }.count
            let nextLineLevels: Int = lines[i + 1 < lines.count
                ? i + 1
                : 0]
                .filter { $0 == "Ψ" }
                .count
            let range = mutattribstring.mutableString.range(of: lines[i], options: .literal)
            if range.location == NSNotFound {
                mutableAttribString.append(NSAttributedString(string: "\n"))
                continue
            }
            if levels > previousLevel {
                for _ in 0..<levels - previousLevel {
                    mutableAttribString.append(NSAttributedString(string: "›"))
                }
            }
            mutableAttribString.append(mutattribstring.attributedSubstring(from: range))
            if nextLineLevels < levels {
                for _ in 0..<levels - nextLineLevels {
                    mutableAttribString.append(NSAttributedString(string: "‹"))
                }
            }
            mutableAttribString.append(NSAttributedString(string: "\n"))
            previousLevel = levels
        }

        return (plainText: plainText, attribString: mutableAttribString.replacingOccurrences(ofWith: ["Ψ" : ""]))
    }
}

// MARK: - Private

extension HtmlConversions {
    private func inlineAttachmentRange(attributedString: NSAttributedString) -> [NSRange] {

        var inlineAttachmentRange = [NSRange]()

        attributedString
            .enumerateAttributes(in: attributedString.wholeRange(),
                                 options: NSAttributedString.EnumerationOptions.longestEffectiveRangeNotRequired) { (attributes, range, stop) in
                                    let line = attributedString.attributedSubstring(from: range)
                                    if line.string.isAttachment {
                                        inlineAttachmentRange.append(range)
                                    }

        }

        return inlineAttachmentRange
    }


    /// Counting "›" and "‹" special chars (in our case) to get difference levels for citation
    /// We use these chars (similar to <blockquote> tags) for cite in HTML
    /// - Parameter text: String with "›" and "‹" special chars
    private func blockquoteLevel(text: String) -> Int {
        var level = 0

        for char in text {
            switch char {
            case "›":
                level = level + 1
            case "‹":
                level = level - 1
            case " ":
                break
            default:
                return level
            }
        }

        return level
    }
}
