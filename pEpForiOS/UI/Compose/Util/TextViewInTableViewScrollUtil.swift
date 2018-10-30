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
    static func scrollCaretToVisible(tableView: UITableView, textView: UITextView) {
        guard let uiRange = textView.selectedTextRange, uiRange.isEmpty else {
            // No selection, nothing to scroll to.
            return
        }
        let selectedRect = textView.caretRect(for: uiRange.end)
        var tvRect = tableView.convert(selectedRect, from: textView)

        // Extend the rectangle in both directions vertically,
        // to both include 1 line above and below.
        tvRect.origin.y -= tvRect.size.height
        tvRect.size.height *= 3

        tableView.scrollRectToVisible(tvRect, animated: false)
    }
}
