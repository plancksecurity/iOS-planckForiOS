//
//  String+Html.swift
//  pEpIOSToolbox
//
//  Created by Adam Kowalski on 04/06/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

extension String {

    /// Removes fixed font size and replace to relative font size
    ///
    /// This function only changes the font size between <style> </style> tags.
    /// The rest of HTML is ignored.
    /// - Returns: HTML string with relative font size (+1, +2, -1)
    public func fixedFontSizeRemover() -> String {

        guard let startIndex = self.range(of: "<style"),
            let endIndex = self.range(of: "</style>"),
            startIndex.lowerBound < endIndex.upperBound else {
                Log.shared.errorAndCrash(message: "Range is wrong!")
                return self
        }

        let styleTagsRange = startIndex.lowerBound...endIndex.upperBound
        let styleTags = String(self[styleTagsRange])
        let attributes = styleTags.components(separatedBy: ";")

        var htmlWithRelativeFontSize = ""

        for partOfAttributes in attributes {
            var line = partOfAttributes

            for match in partOfAttributes.find(pattern: "font(.*):(.*?)px") {
                if let newFontSize = removeOrReplaceFixedFont(fontSize: match) {
                    line = line
                        .replacingOccurrences(of: match,
                                              with: match.replacingOccurrences(of: match,
                                                                               with: newFontSize))
                } else {
                    line = line
                        .replacingOccurrences(of: match,
                                              with: "")
                }
            }
            htmlWithRelativeFontSize = htmlWithRelativeFontSize + line + ";"
        }

        htmlWithRelativeFontSize.removeLast()

        var completeHtmlStringAfterConversion = self
        completeHtmlStringAfterConversion.removeSubrange(styleTagsRange)
        completeHtmlStringAfterConversion.insert(contentsOf: htmlWithRelativeFontSize,
                                                 at: startIndex.lowerBound)

        return completeHtmlStringAfterConversion
    }

    private func removeOrReplaceFixedFont(fontSize: String) -> String? {

        guard let separatorIndex = fontSize.firstIndex(of: ":"),
            let dotSeparator = fontSize.firstIndex(of: ".") else {
                Log.shared.errorAndCrash(message: "Index is wrong!")
                return fontSize
        }

        let spaceIndex = fontSize.index(separatorIndex, offsetBy: 1)

        let firstSegment = fontSize[fontSize.startIndex...spaceIndex]
        let size = String(fontSize[spaceIndex..<dotSeparator])

        var relativeFontSize: String?

        if let number = Int(size.trimmingCharacters(in: .whitespacesAndNewlines)) {
            switch number {
            case 0...11:
                relativeFontSize = firstSegment + "x-small"
            case 12...13:
                relativeFontSize = firstSegment + "small"
            case 14...15:
                relativeFontSize = firstSegment + "smaller"
            case 16...17:
                relativeFontSize = nil
            case 18...21:
                relativeFontSize = firstSegment + "larger"
            case 22...25:
                relativeFontSize = firstSegment + "large"
            case 26...80:
                relativeFontSize = firstSegment + "x-large"
            default:
                relativeFontSize = nil
            }
        }

        return relativeFontSize
    }
}
