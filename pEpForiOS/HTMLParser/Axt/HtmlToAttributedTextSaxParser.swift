//
//  HtmlToAttributedTextSaxParser.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

public protocol HtmlToAttributedTextSaxParserAttachmentDelegate: class {
    func imageAttachment(src: String?, alt: String?) -> Attachment?
}

class HtmlToAttributedTextSaxParser: HtmlToTextSaxParser {
    var attributedOutput = NSMutableAttributedString()
    let defaultFont = UIFont.preferredFont(forTextStyle: .body)

    weak var attachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate?

    override func add(string: String) {
        attributedOutput.append(
            NSAttributedString(string: string,
                               attributes: [NSAttributedString.Key(rawValue: "NSFont"): defaultFont]))
    }

    override func parser(_ parser: AXHTMLParser, didStartElement elementName: String,
                attributes attributeDict: [AnyHashable : Any] = [:]) {
        if elementName == "img" {
            let src = attributeDict["src"] as? String
            let alt = attributeDict["alt"] as? String
            if let attachment = attachmentDelegate?.imageAttachment(src: src, alt: alt) {
                let textAttachment = TextAttachment()
                textAttachment.image = attachment.image
                textAttachment.attachment = attachment
                let imageString = NSAttributedString(attachment: textAttachment)
                attributedOutput.append(imageString)
            }
        }
        super.parser(parser, didStartElement: elementName)
    }
}
