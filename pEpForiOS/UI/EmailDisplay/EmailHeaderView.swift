//
//  EmailHeaderView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class EmailHeaderView: UIView {
    let insetsX: CGFloat = 5
    let insetsY: CGFloat = 5
    let labelGapX: CGFloat = 5
    let labelGapY: CGFloat = 5
    let biggerLabelGapY: CGFloat = 10

    var preferredSize: CGSize = CGSizeZero

    var lastLeftLabel: UILabel? = nil

    var message: Message!

    func update(width: CGFloat) {
        while subviews.count > 0 {
            subviews.first?.removeFromSuperview()
        }

        var pos = CGPointMake(insetsX, insetsY)
        pos = addFromAtPosition(pos, width: width)

        if message.to.count > 0 {
            pos = addRecipients(message.to,
                                title: NSLocalizedString("To",
                                    comment: "Header label for email display"),
                                position: pos, width: width)
        }
        if message.cc.count > 0 {
            pos = addRecipients(message.cc,
                                title: NSLocalizedString("Cc",
                                    comment: "Header label for email display"),
                                position: pos, width: width)
        }
        if message.bcc.count > 0 {
            pos = addRecipients(message.bcc,
                                title: NSLocalizedString("Bcc",
                                    comment: "Header label for email display"),
                                position: pos, width: width)
        }

        if let subject = message.subject {
            pos = biggerNewline(pos)
            let subjectLabel = headerBaseLabelWithText(subject, maxWidth: width)
            subjectLabel.frame.origin = pos
            addSubview(subjectLabel)
            pos.x = labelGapX
            pos.y += subjectLabel.bounds.height
        }

        preferredSize = CGSizeMake(width, pos.y)
    }

    func addRecipients(recipients: NSOrderedSet, title: String, position: CGPoint,
                       width: CGFloat) -> CGPoint {
        var pos = newline(position)

        let titleString = "\(title):"
        let titleLabel = headerBaseLabelWithText(titleString)
        titleLabel.frame.origin = pos
        addSubview(titleLabel)
        var lastUsedLabel = titleLabel

        for rec in recipients {
            if let contact = rec as? Contact {
                let recLabel = recipientBaseLabelWithText(contact.displayString())
                pos = putAdjacentLeftLabel(lastUsedLabel, rightLabel: recLabel, atLeftPos: pos,
                                           width: width)
                lastUsedLabel = recLabel
                addSubview(recLabel)
            }
        }

        return pos
    }

    func addFromAtPosition(position: CGPoint, width: CGFloat) -> CGPoint {
        var pos = position
        let fromTitleLabel = headerBaseLabelWithText(
            NSLocalizedString("From:",
                comment: "Header label for email display"))
        fromTitleLabel.frame.origin = pos
        lastLeftLabel = fromTitleLabel

        let fromLabel = recipientBaseLabelWithText(message.from?.displayString())
        pos = putAdjacentLeftLabel(fromTitleLabel, rightLabel: fromLabel, atLeftPos: pos,
                                   width: width)

        addSubview(fromTitleLabel)
        addSubview(fromLabel)

        return pos
    }

    func putAdjacentLeftLabel(leftLabel: UILabel, rightLabel: UILabel,
                              atLeftPos: CGPoint, width: CGFloat) -> CGPoint {
        var pos = atLeftPos

        let leftSize = leftLabel.intrinsicContentSize()
        let rightSize = rightLabel.intrinsicContentSize()

        if rightSize.width + leftLabel.frame.origin.x + leftSize.width + labelGapX
            + insetsX < width {
            // They fit adjacent
            rightLabel.frame.origin = pos
            rightLabel.frame.origin.x = pos.x + leftSize.width + labelGapX
            pos = rightLabel.frame.origin
        } else {
            // do a newline
            pos.x = insetsX
            pos.y = pos.y + leftLabel.bounds.height + labelGapY
            rightLabel.frame.origin = pos
            lastLeftLabel = rightLabel
        }

        return pos
    }

    func newline(pos: CGPoint) -> CGPoint {
        return newline(pos, gap: labelGapY)
    }

    func biggerNewline(pos: CGPoint) -> CGPoint {
        return newline(pos, gap: biggerLabelGapY)
    }

    func newline(pos: CGPoint, gap: CGFloat) -> CGPoint {
        if let last = lastLeftLabel {
            return CGPointMake(insetsX, last.frame.origin.y + last.frame.size.height + gap)
        } else {
            return CGPointMake(insetsX, pos.y + gap)
        }
    }

    func labelWithFont(font: UIFont, text: String?, maxWidth: CGFloat? = nil) -> UILabel {
        let label = UILabel.init()
        label.font = font

        if let t = text {
            label.text = t
        }

        if let max = maxWidth {
            label.preferredMaxLayoutWidth = max
            label.lineBreakMode = .ByWordWrapping
            label.numberOfLines = 0
            var size = label.sizeThatFits(CGSizeMake(max, 0))
            size.width = max
            label.frame.size = size
        } else {
            label.sizeToFit()
        }

        return label
    }

    func headerBaseLabelWithText(text: String?, maxWidth: CGFloat? = nil) -> UILabel {
        return labelWithFont(UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
                             text: text, maxWidth: maxWidth)
    }

    func recipientBaseLabelWithText(text: String?, maxWidth: CGFloat? = nil) -> UILabel {
        return labelWithFont(UIFont.preferredFontForTextStyle(UIFontTextStyleBody),
                             text: text, maxWidth: maxWidth)
    }
}