//
//  NSAttributedString+Parsing.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

protocol NSAttributedStringParsingDelegate: class {
    func stringFor(attachment: NSTextAttachment) -> String
    func stringFor(string: String) -> String
}

extension NSAttributedString {
    func oldToHtml() -> String {
        let string = NSMutableAttributedString(attributedString: self)
        string.fixAttributes(in: string.wholeRange())

        let documentType = NSHTMLTextDocumentType
        let docAttributes = [NSDocumentTypeDocumentAttribute: documentType]
        do {
            let data = try string.data(from: string.wholeRange(), documentAttributes: docAttributes)
            let html = String(data: data, encoding: .utf8)
            return html ?? ""
        } catch {
            Log.error(component: #function, errorString: "Could not convert into \(documentType)")
            return ""
        }
    }

    func convert(delegate: NSAttributedStringParsingDelegate) -> String {
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
                let theStringToAppend = delegate.stringFor(string: theString)
                resultString = "\(resultString)\(theStringToAppend)"
            }
        }
        return resultString
    }
}
