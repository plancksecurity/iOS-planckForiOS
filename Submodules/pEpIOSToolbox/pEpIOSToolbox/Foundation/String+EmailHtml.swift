//
//  String+Html.swift
//  pEpIOSToolbox
//
//  Created by Adam Kowalski on 04/06/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

extension String {

    /// Replaces fixed `font-size:` attribute values (e.g. `font-size: 18px`) with the best possible
    /// relative value ((e.g. `font-size: larger`).
    ///
    /// Background: A fixed font size wil always be too small/big in certain mail clients. The mail
    /// client should be able to decide how bit fonts are displayed. We still want to keep the
    /// formatting of mails (e.g. a forwarded mail) as good as possible. So we tell the receivers
    /// mail client which fonts shouldbe bigger / smaller relative to its (the receivers mail
    /// client) default font size by passing relative font size values.
    ///
    /// This function only changes the font size between <style> </style> tags.
    /// The rest of HTML is ignored.
    /// - Returns: HTML string with fixed `font-size:` values replaced by relative values
    public func fixedFontSizeRemoved() -> String {

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

        for attribute in attributes {
            var line = attribute
            for match in attribute.find(pattern: "font-size:.*?(px|pt)") {
                let newFontSize = relativeFontSize(forFixedFontSize: match)
                line = line.replacingOccurrences(of: match,
                                                 with: match.replacingOccurrences(of: match,
                                                                                  with: newFontSize))
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


    /// Tries to figure out the best relative font size for a given fixed font size.
    /// - Parameter fixedFontSize: font size attribute. E.g. "font-size: 16.0px"
    /// - Returns: font size attribute with best matching relative value value (e.g. "font-size: smaller").
    private func relativeFontSize(forFixedFontSize fixedFontSize : String) -> String {
        let defaultFontSize = "normal"
        guard let separatorIndex = fixedFontSize.firstIndex(of: ":"),
            let dotSeparator = fixedFontSize.firstIndex(of: ".") else {
                Log.shared.errorAndCrash(message: "Unexpected input. Maybe unhandled case. Investigate!")
                return defaultFontSize
        }

        let spaceIndex = fixedFontSize.index(separatorIndex, offsetBy: 1)

        let fontSizeAttributeNameSegment = fixedFontSize[fixedFontSize.startIndex...spaceIndex]
        let size = String(fixedFontSize[spaceIndex..<dotSeparator])

        guard let number = Int(size.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            Log.shared.errorAndCrash(message: "No fixed font size valu? Unexpected! Maybe unhandled valid input? Investigate!")
            return defaultFontSize
        }
        var relativeFontSizeValue: String
        switch number {
        case 0...11:
            relativeFontSizeValue = "x-small"
        case 12...13:
            relativeFontSizeValue = "small"
        case 14...15:
            relativeFontSizeValue = "smaller"
        case 16...17:
            relativeFontSizeValue = defaultFontSize
        case 18...21:
            relativeFontSizeValue = "larger"
        case 22...25:
            relativeFontSizeValue = "large"
        case 26...80:
            relativeFontSizeValue = "x-large"
        default:
            relativeFontSizeValue = defaultFontSize
        }

        return fontSizeAttributeNameSegment + relativeFontSizeValue
    }
}
