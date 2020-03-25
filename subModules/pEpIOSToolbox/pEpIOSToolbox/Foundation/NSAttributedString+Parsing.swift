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

        let htmlConversion = HtmlConversions()

        let attribStringWithGratherThanChars = htmlConversion
        .citedTextGratherThanChars(attribText: self,
                                   addCitationLevel: addCitationLevel)

        let attribStringWithVerticalLines = htmlConversion.citationGraterThanToVerticalLines(attribText: attribStringWithGratherThanChars)

        return attribStringWithVerticalLines
    }

    /// Replace given keys to given value  using occurrences
    /// - Parameter ofWith: [key - (find key) String : value - (replace with)  String / NSAttribString]
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
                } else if let value = ofWith[charToReplace] as? NSAttributedString {
                    attributedString.replaceCharacters(in: range, with: value)
                }
            }
        }

        return NSAttributedString(attributedString: attributedString)
    }
}
