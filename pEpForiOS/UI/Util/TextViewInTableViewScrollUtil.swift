//
//  TextViewInTableViewScrollUtil.swift
//  pEp
//
//  Created by Dirk Zimmermann on 03.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Small utility to share some scrolling behavior of text views contained
 in table views (basically "scroll-to-caret-on-edit").
 */
class TextViewInTableViewScrollUtil {

    /**
     Makes sure that the given text view's cursor (if any) is visible, given that it is
     contained in the given table view.
     */
    static func assureCaretVisibility(tableView: UITableView, textView: UITextView) {
        guard let uiRange = textView.selectedTextRange, uiRange.isEmpty else {
            // No selection, nothing to scroll to.
            return
        }
        let caretRect = textView.caretRect(for: uiRange.end)
        let tvCaretRect = tableView.convert(caretRect, from: textView)


        // Extend the rectangle in both directions vertically,
        // to both include 1 line above and below.
        var adjusted = tvCaretRect
        adjusted.origin.y -= adjusted.size.height
        adjusted.size.height *= 3

        // The offset must not be negative
        var tvRect = adjusted.origin.y >= 0.0 ? adjusted : tvCaretRect

        // A cursor might be big. E.g. height of an image text attachments.
        // Do not take adjusted rect in this case. It will explode.
        let maxCursorHeight: CGFloat = 100.0
        tvRect = tvRect.size.height <= maxCursorHeight ? tvRect : tvCaretRect

        tableView.scrollRectToVisible(tvRect, animated: false)
    }
}
