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

    func toHtml() -> String? {
        let htmlDocAttrib = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]

        guard let htmlData = try? self.data(from: self.wholeRange(),
                                            documentAttributes: htmlDocAttrib) else {
                                                return nil
        }
        let html = String(data: htmlData, encoding: .utf8) ?? nil
        return html
    }

    func toCitation() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: self)
        var newParagraphs: [Int] = []
        var levels: [Int] = [0]
        var index = 0

        for char in attributedString.string {
            index = index + 1
            switch char  {
            case "›":
                levels.append(index)
            case "‹":
                levels.removeLast()
            default:
                break
            }
            if char.isNewline() {
                for _ in levels {
                    newParagraphs.append(index)
                }
            }
        }

        let fontAvenir = UIFont(name: "Avenir Next Condensed Ultra Light", size: 15)
        let fontSystem = UIFont.systemFont(ofSize: 15, weight: .light)

        let fakeVerticalLine = NSAttributedString(string: " ", attributes: [NSAttributedString.Key.backgroundColor : UIColor.pEpGreen, NSAttributedString.Key.font : fontAvenir ?? fontSystem])
        let horizontalSpace = NSAttributedString(string: " ", attributes: [
            NSAttributedString.Key.backgroundColor : UIColor.clear,
            NSAttributedString.Key.font : fontAvenir ?? fontSystem])

        var offset = 0

        for index in newParagraphs {
            attributedString.insert(fakeVerticalLine, at: index + offset)
            attributedString.insert(horizontalSpace, at: index + 1 + offset)
            attributedString.insert(horizontalSpace, at: index + 2 + offset)
            offset = offset + 3
        }
        return attributedString.replacingOccurrences(ofWith: ["›" : "", "‹" : "\n"])
    }

    func replacingOccurrences(ofWith: [String: String]) -> NSAttributedString {

        let attributedString = NSMutableAttributedString(attributedString: self)
        let charsToReplace = Array(ofWith.keys.map { String($0) })

        for charToReplace in charsToReplace {
            while attributedString.mutableString.contains(charToReplace) {
                let range = attributedString.mutableString.range(of: charToReplace)
                guard range.lowerBound != NSNotFound else {
                    // early quit, nothing to do and also avoid an endless loop
                    break
                }
                attributedString.replaceCharacters(in: range, with: ofWith[charToReplace] ?? "")
            }
        }

        return NSAttributedString(attributedString: attributedString)
    }
}
