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
                              maxWidth: CGFloat = 0.0,
                              margin: CGFloat = 20.0)
        -> (newString: NSAttributedString,  attachment: RecipientTextViewTextAttachment) {
        let attrText = NSMutableAttributedString(attributedString: self)
        let img = ComposeHelper.recipient(identity.address,
                                          textColor: .pEpGreen,
                                          maxWidth: maxWidth - margin)
        let at = RecipientTextViewTextAttachment(recipient: identity)
        at.image = img
        at.fontDescender = UIFont.pEpInput.descender
        let attachString = NSAttributedString(attachment: at)
        attrText.replaceCharacters(in: selectedRange, with: attachString)
        attrText.addAttribute(NSAttributedStringKey.font,
                              value: UIFont.pEpInput,
                              range: NSRange(location: 0, length: attrText.length)
        )
        return (NSAttributedString(attributedString: attrText), at)
    }
}
