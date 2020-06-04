//
//  String+Html.swift
//  pEpIOSToolbox
//
//  Created by Adam Kowalski on 04/06/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

extension String {
    public func fixedFontSizeReplacer() -> String {

        guard let startIndex = self.range(of: "<style"),
            let endIndex = self.range(of: "</style>"),
            startIndex.lowerBound < endIndex.upperBound else {
                Log.shared.errorAndCrash(message: "Range is wrong!")
                return self
        }

        let range = startIndex.lowerBound...endIndex.upperBound

        let interestedString = String(self[range])

        let components = interestedString.components(separatedBy: ";")

        var replaceTo = ""

        for c in components {
            var line = c

            for match in c.find(pattern: "font(.*):(.*?)px") {
                if let newFontSize = removeOrReplaceFixedFont(fontSize: match) {
                    line = line.replacingOccurrences(of: match, with: match.replacingOccurrences(of: match, with: newFontSize))
                } else {
                    line = line.replacingOccurrences(of: match, with: "")
                }
            }
            replaceTo = replaceTo + line + ";"
        }

        replaceTo.removeLast()

        var newString = self
        newString.removeSubrange(range)
        newString.insert(contentsOf: replaceTo, at: startIndex.lowerBound)

        return newString
    }

    private func removeOrReplaceFixedFont(fontSize: String) -> String? {

        guard let separatorIndex = fontSize.firstIndex(of: ":"),
            let dotSeparator = fontSize.firstIndex(of: ".") else { return fontSize }

        let spaceIndex = fontSize.index(separatorIndex, offsetBy: 1)

        let firstSegment = fontSize[fontSize.startIndex...separatorIndex]
        let size = String(fontSize[spaceIndex..<dotSeparator])

        var newSize: String?

        if let number = Int(size.trimmingCharacters(in: .whitespacesAndNewlines)) {
            switch number {
            case 0..<13:
                newSize = firstSegment + " -2"
            case 13...16:
                newSize = firstSegment + " -1"
            case 14...17:
                newSize = nil
            case 18...21:
                newSize = firstSegment + " +1"
            case 22...25:
                newSize = firstSegment + " +2"
            case 26...38:
                newSize = firstSegment + " +3"
            default:
                newSize = nil
            }
        } else {
            fatalError()
        }

        return newSize
    }
}
