//
//  EmailHeaderView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class EmailHeaderView: UIView {
    /**
     Where to start laying out labels from the left.
     */
    let insetsX: CGFloat = 5

    /**
     Some extra padding from the left when we have to break apart labels that belong together.
     */
    let insetsNewlineX: CGFloat = 5

    /**
     Where to start laying out labels from the top.
     */
    let insetsY: CGFloat = 5

    /** Horizontal gap between labels that belong in one row.
     */
    let labelGapX: CGFloat = 5

    /**
     Vertical gap between lines of labels.
     */
    let labelGapY: CGFloat = 5

    /**
     Vertical gap between different sections.
     */
    let biggerLabelGapY: CGFloat = 10

    /**
     The size we need to layout all labels, dependent on the input width.
     */
    var preferredSize: CGSize = CGSize.zero

    /**
     The last label we layed out on the left side.
     */
    var lastLeftLabel: UILabel? = nil

    var message: Message!

    let dateFormatter = UIHelper.dateFormatterEmailDetails()

    /**
     Layout the message header contents.

     - Parameter width: The maximum width the layout should use. Very important for
     determining line breaks.
     */
    func update(_ width: CGFloat) {
        while subviews.count > 0 {
            subviews.first?.removeFromSuperview()
        }

        var pos = CGPoint(x: insetsX, y: insetsY)
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

        if let date = message.received {
            pos = biggerNewline(pos)
            let dateLabel = headerBaseLabelWithText(dateFormatter.string(from: date as Date),
                                                    maxWidth: width)
            dateLabel.frame.origin = pos
            addSubview(dateLabel)
            pos.x = labelGapX
            pos.y += dateLabel.bounds.height
            lastLeftLabel = dateLabel
        }

        if let subject = message.shortMessage {
            pos = biggerNewline(pos)
            let subjectLabel = headerBaseLabelWithText(subject, maxWidth: width)
            subjectLabel.frame.origin = pos
            addSubview(subjectLabel)
            pos.x = labelGapX
            pos.y += subjectLabel.bounds.height
            lastLeftLabel = subjectLabel
        }

        preferredSize = CGSize(width: width, height: pos.y)
    }

    func addRecipients(_ recipients: [Identity], title: String, position: CGPoint,
                       width: CGFloat) -> CGPoint {
        var pos = newline(position)

        let titleString = "\(title):"
        let titleLabel = headerBaseLabelWithText(titleString)
        titleLabel.frame.origin = pos
        addSubview(titleLabel)
        lastLeftLabel = titleLabel
        var lastUsedLabel = titleLabel

        let session = PEPSession.init()
        for rec in recipients {
            let recLabel = recipientBaseLabelWithText(rec.displayString)
            let privacyColor = PEPUtil.privacyColor(identity: rec, session: session)
            UIHelper.setBackgroundColor(
                privacyColor, forLabel: recLabel, defaultColor: recLabel.backgroundColor)
            pos = putAdjacentLeftLabel(lastUsedLabel, rightLabel: recLabel, atLeftPos: pos,
                                       width: width)
            lastUsedLabel = recLabel
            addSubview(recLabel)
        }

        return pos
    }

    func addFromAtPosition(_ position: CGPoint, width: CGFloat) -> CGPoint {
        var pos = position
        let fromTitleLabel = headerBaseLabelWithText(
            NSLocalizedString("From:",
                comment: "Header label for email display"))
        fromTitleLabel.frame.origin = pos
        lastLeftLabel = fromTitleLabel

        if let fromContact = message.from {
            let fromLabel = recipientBaseLabelWithText(fromContact.displayString)
            let privacyColor = PEPUtil.privacyColor(identity: fromContact)
            UIHelper.setBackgroundColor(
                privacyColor, forLabel: fromLabel, defaultColor: fromLabel.backgroundColor)

            pos = putAdjacentLeftLabel(fromTitleLabel, rightLabel: fromLabel, atLeftPos: pos,
            width: width)

            addSubview(fromTitleLabel)
            addSubview(fromLabel)
        }

        return pos
    }

    func putAdjacentLeftLabel(_ leftLabel: UILabel, rightLabel: UILabel,
                              atLeftPos: CGPoint, width: CGFloat) -> CGPoint {
        var pos = atLeftPos

        let leftSize = leftLabel.intrinsicContentSize
        let rightSize = rightLabel.intrinsicContentSize

        if rightSize.width + leftLabel.frame.origin.x + leftSize.width + labelGapX
            + insetsX < width {
            // They fit adjacent
            rightLabel.frame.origin = pos
            rightLabel.frame.origin.x = pos.x + leftSize.width + labelGapX
            pos = rightLabel.frame.origin
        } else {
            // do a newline
            pos.x = insetsX + insetsNewlineX
            pos.y = pos.y + leftLabel.bounds.height + labelGapY
            rightLabel.frame.origin = pos
            lastLeftLabel = rightLabel
        }

        return pos
    }

    func newline(_ pos: CGPoint) -> CGPoint {
        return newline(pos, gap: labelGapY)
    }

    func biggerNewline(_ pos: CGPoint) -> CGPoint {
        return newline(pos, gap: biggerLabelGapY)
    }

    func newline(_ pos: CGPoint, gap: CGFloat) -> CGPoint {
        if let last = lastLeftLabel {
            return CGPoint(x: insetsX, y: last.frame.origin.y + last.frame.size.height + gap)
        } else {
            return CGPoint(x: insetsX, y: pos.y + gap)
        }
    }

    func labelWithFont(_ font: UIFont, text: String?, maxWidth: CGFloat? = nil) -> UILabel {
        let label = UILabel.init()
        label.font = font

        if let t = text {
            label.text = t
        }

        if let max = maxWidth {
            label.preferredMaxLayoutWidth = max
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            var size = label.sizeThatFits(CGSize(width: max, height: 0))
            size.width = max
            label.frame.size = size
        } else {
            label.sizeToFit()
        }

        return label
    }

    func headerBaseLabelWithText(_ text: String?, maxWidth: CGFloat? = nil) -> UILabel {
        return labelWithFont(UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline),
                             text: text, maxWidth: maxWidth)
    }

    func recipientBaseLabelWithText(_ text: String?, maxWidth: CGFloat? = nil) -> UILabel {
        return labelWithFont(UIFont.preferredFont(forTextStyle: UIFontTextStyle.body),
                             text: text, maxWidth: maxWidth)
    }
}
