//
//  RecipientTextViewModel+TextAttachment.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import PlanckToolboxForExtensions
#else
import MessageModel
import PlanckToolbox
#endif

extension RecipientTextViewModel {

    public class TextAttachment: NSTextAttachment {
        public private(set) var recipient: Identity
        private var font: UIFont
        public var isBadge: Bool = false

        init(recipient: Identity,
             font: UIFont = UIFont.planckFont(style: .footnote, weight: .regular),
             textColor: UIColor = .pEpDarkText,
             maxWidth: CGFloat = 0.0) {
            self.recipient = recipient
            self.font = font
            super.init(data: nil, ofType: nil)
            setupRecipientImage(for: recipient,
                                font: font,
                                textColor: textColor,
                                maxWidth: maxWidth)
        }

        required init?(coder aDecoder: NSCoder) {
            recipient = Identity(address: "")
            font = UIFont.systemFont(ofSize: 12)
            super.init(coder: aDecoder)
            Log.shared.errorAndCrash(message: "init(coder:) has not been implemented")
        }

        public override func attachmentBounds(for textContainer: NSTextContainer?,
                                              proposedLineFragment lineFrag: CGRect,
                                              glyphPosition position: CGPoint,
                                              characterIndex charIndex: Int) -> CGRect {
            var superRect = super.attachmentBounds(for: textContainer,
                                                   proposedLineFragment: lineFrag,
                                                   glyphPosition: position,
                                                   characterIndex: charIndex)
            //Make sure typed text aligns well with the characters in the text attachment's image
            superRect.origin.y += font.descender
            return superRect
        }

        private func getBadgeAttributes() -> [NSAttributedString.Key : NSObject] {
            return [
                NSAttributedString.Key.foregroundColor: UIColor.label,
                NSAttributedString.Key.font: font,
            ]
        }

        private func getRecipientsAttributes(textColor: UIColor) -> [NSAttributedString.Key : NSObject] {
            let recipientBackgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor.pEpLightBackground : UIColor.pEpGreyRecipientBackground
            return [
                NSAttributedString.Key.foregroundColor: textColor,
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.backgroundColor: recipientBackgroundColor
            ]
        }

        private func setupRecipientImage(for recipient: Identity,
                                         font:  UIFont,
                                         textColor: UIColor = .pEpDarkText,
                                         maxWidth: CGFloat = 0.0) {
            var text: String
            if let username = recipient.userName, username.isEmpty {
                text = " \(recipient.address) "
            } else {
                text = " \(recipient.userName ?? recipient.address) "
            }
            let badgeAttributes = getBadgeAttributes()
            var attributes = getRecipientsAttributes(textColor: textColor)
            let textMargin: CGFloat = 3.0

            if !recipient.address.isProbablyValidEmail() {
                attributes = badgeAttributes
            }

            let textSize = text.size(withAttributes: attributes)
            let width = textSize.width > maxWidth ? maxWidth : textSize.width
            var textFrame = CGRect(x: 0, y: 0, width: width, height: textSize.height)

            let label = UILabel()
            label.font = font
            label.text = "Some text to get a height"
            label.sizeToFit()

            var imageSize = label.bounds.size
            imageSize.width = 0
            let textPosX = textMargin
            let imageWidth = textFrame.width + (textMargin * 2)

            textFrame.origin = CGPoint(x: textPosX,
                                       y: round((imageSize.height - textFrame.size.height) / 2))
            imageSize.width = imageWidth
            imageSize.height = textFrame.size.height
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)

            text.draw(with: textFrame,
                      options: [NSStringDrawingOptions.truncatesLastVisibleLine,
                                NSStringDrawingOptions.usesLineFragmentOrigin],
                      attributes: attributes, context: nil)

            guard let createe = UIGraphicsGetImageFromCurrentImageContext() else {
                Log.shared.errorAndCrash("No img")
                return
            }
            UIGraphicsEndImageContext()

            guard let result = createe.withRoundedCorners(radius: 16) else {
                image = createe
                return
            }
            image = result
        }
    }
}
