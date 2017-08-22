//
//  NSAttributedString+Parsing.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

protocol NSAttributedStringAttachmentDelegate: class {
    func stringFor(attachment: NSTextAttachment) -> String
}

extension NSAttributedString {
    func toMarkdown(delegate: NSAttributedStringAttachmentDelegate) -> String {
        var resultString = ""
        let string = NSMutableAttributedString(attributedString: self)
        string.fixAttributes(in: string.wholeRange())
        string.enumerateAttributes(in: string.wholeRange(), options: []) { attrs, r, stop in
            if let attachment = attrs["NSAttachment"] as? NSTextAttachment {
                let attachmentString = delegate.stringFor(attachment: attachment)
                resultString = "\(resultString)\(attachmentString)"
            } else {
                let theAttributedString = string.attributedSubstring(from: r)
                let theString = theAttributedString.string
                resultString = "\(resultString)\(theString)"
            }
        }
        return resultString
    }
}
