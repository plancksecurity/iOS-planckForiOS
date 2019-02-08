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
    func stringFor(string: String) -> String?
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
                if let theStringToAppend = delegate.stringFor(string: theString) {
                    resultString = "\(resultString)\(theStringToAppend)"
                }
            }
        }
        return resultString
    }
}
