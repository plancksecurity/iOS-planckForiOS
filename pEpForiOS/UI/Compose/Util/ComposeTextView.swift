
//
//  ComposeTextView.swift
//
//  Created by Igor Vojinovic on 11/4/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit

import MessageModel //IOS-1369: UIView should not know model

//IOS-1369: try to get rid of
open class ComposeTextView: UITextView {
    public var fieldModel: ComposeFieldModel?
    
    private final var fontDescender: CGFloat = -7.0
    final var textBottomMargin: CGFloat = 25.0
    private final var imageFieldHeight: CGFloat = 66.0

    let scrollUtil = TextViewInTableViewScrollUtil()

    //IOS-1369: should (all?) go to UITextViewExtention

    public func insertImage(with text: String, maxWidth: CGFloat = 0.0) {
        let attrText = NSMutableAttributedString(attributedString: attributedText)
        let img = ComposeHelper.recipient(text, textColor: .pEpGreen, maxWidth: maxWidth - 20.0)
        let at = TextAttachment()
        at.image = img
        at.bounds = CGRect(x: 0, y: fontDescender, width: img.size.width, height: img.size.height)
        let attachString = NSAttributedString(attachment: at)
        attrText.replaceCharacters(in: selectedRange, with: attachString)
        attrText.addAttribute(NSAttributedStringKey.font,
                              value: UIFont.pEpInput,
                              range: NSRange(location: 0, length: attrText.length)
        )
        attributedText = attrText
    }

    public var fieldHeight: CGFloat {
        get {
            let size = sizeThatFits(CGSize(width: frame.size.width,
                                           height: CGFloat(Float.greatestFiniteMagnitude)))
            return size.height + textBottomMargin
        }
    }

    public func scrollToBottom() {
        if fieldHeight >= imageFieldHeight {
            setContentOffset(CGPoint(x: 0.0, y: fieldHeight - imageFieldHeight), animated: true)
        }
    }

    public func scrollToTop() {
        contentOffset = .zero
    }

    public func addNewlinePadding() {
        // Does nothing for recipient text views.
    }

    /**
     Invoke any actions needed after the text has changed, i.e. forcing the table to
     pick up the new size and scrolling to the current cursor position.
     */
    public func layoutAfterTextDidChange(tableView: UITableView) {
        // Does nothing for recipient text views.
    }

    func scrollCaretToVisible(tableView: UITableView) {
        scrollUtil.scrollCaretToVisible(tableView: tableView, textView: self)
    }
}
