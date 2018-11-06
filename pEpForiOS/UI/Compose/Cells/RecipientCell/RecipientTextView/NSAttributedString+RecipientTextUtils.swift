//
//  NSAttributedString+RecipientTextUtils.swift
//  pEp
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - RecipientTextUtils

extension NSAttributedString {

    public func imageInserted(withAddressOf identity: Identity,
                              in selectedRange: NSRange,
                              maxWidth: CGFloat = 0.0)
        -> (newString: NSAttributedString,  attachment: RecipientTextViewTextAttachment) {
            let margin: CGFloat = 20.0
            let attrText = NSMutableAttributedString(attributedString: self)
            let textAttachment = RecipientTextViewTextAttachment(recipient: identity,
                                                                 maxWidth: maxWidth - margin)
            let attachString = NSAttributedString(attachment: textAttachment)
            attrText.replaceCharacters(in: selectedRange, with: attachString)
            attrText.addAttribute(NSAttributedStringKey.font,
                                  value: UIFont.pEpInput,
                                  range: NSRange(location: 0, length: attrText.length)
            )
            return (NSAttributedString(attributedString: attrText), textAttachment)
    }
}
