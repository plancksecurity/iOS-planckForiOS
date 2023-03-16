//
//  NSAttributedString+RecipientTextUtils.swift
//  pEp
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

// MARK: - RecipientTextUtils

extension NSAttributedString {

    public func imageInserted(withAddressOf identity: Identity,
                              in selectedRange: NSRange,
                              maxWidth: CGFloat = 0.0)
        -> (newString: NSAttributedString,  attachment: RecipientTextViewModel.TextAttachment) {
            let margin: CGFloat = 16.0
            let attrText = NSMutableAttributedString(attributedString: self)

            let textColor = UIColor.pEpDarkText
            let textAttachment = RecipientTextViewModel.TextAttachment(recipient: identity,
                                                                       textColor: textColor,
                                                                       maxWidth: maxWidth - margin)
            let attachString = NSAttributedString(attachment: textAttachment)
            attrText.replaceCharacters(in: selectedRange, with: attachString)
            let pepFont = UIFont.pepFont(style: .body, weight: .regular)
            let range = NSRange(location: 0, length: attrText.length)
            attrText.addAttribute(.font, value: pepFont, range: range)
            return (NSAttributedString(attributedString: attrText), textAttachment)
    }
}
