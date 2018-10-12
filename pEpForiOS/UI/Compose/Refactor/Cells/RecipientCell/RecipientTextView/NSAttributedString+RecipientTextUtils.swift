//
//  NSAttributedString+RecipientTextUtils.swift
//  pEp
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

//IOS-1369: obsolete?

// MARK: - RecipientTextUtils

extension NSAttributedString {

    public func imageInserted(with text: String,
                              in selectedRange: NSRange,
                              fontDescender: CGFloat = -7.0,
                              maxWidth: CGFloat = 0.0,
                              margin: CGFloat = 20.0) -> NSAttributedString {
        let attrText = NSMutableAttributedString(attributedString: self)
        let img = ComposeHelper.recipient(text,
                                          textColor: .pEpGreen,
                                          maxWidth: maxWidth - margin)
        let at = TextAttachment()
        at.image = img
        at.bounds = CGRect(x: 0, y: fontDescender, width: img.size.width, height: img.size.height)
        let attachString = NSAttributedString(attachment: at)
        attrText.replaceCharacters(in: selectedRange, with: attachString)
        attrText.addAttribute(NSAttributedStringKey.font,
                              value: UIFont.pEpInput,
                              range: NSRange(location: 0, length: attrText.length)
        )
        return attrText
    }
}
