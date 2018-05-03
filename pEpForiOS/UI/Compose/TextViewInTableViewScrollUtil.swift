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
    public func layoutAfterTextDidChange(tableView: UITableView, textView: UITextView) {
        tableView.updateSize() { [weak self] in
            if let theSelf = self {
                Timer.scheduledTimer(timeInterval: 0.01,
                                     target: theSelf,
                                     selector: #selector(theSelf.timerScroll),
                                     userInfo: (tableView, textView),
                                     repeats: false)
            }
        }
    }

    /**
     Makes sure that the given text view's cursor (if any) is visible, given that it is
     contained in the given table view.
     */
    func scrollCaretToVisible(tableView: UITableView, textView: UITextView) {
        if let uiRange = textView.selectedTextRange, uiRange.isEmpty {
            let selectedRect = textView.caretRect(for: uiRange.end)
            var tvRect = tableView.convert(selectedRect, from: textView)

            // Extend the rectangle in both directions vertically,
            // to both include 1 line above and below.
            tvRect.origin.y -= tvRect.size.height
            tvRect.size.height *= 3

            tableView.scrollRectToVisible(tvRect, animated: false)
        }
    }

    @objc private func timerScroll(_ timer: Timer) {
        guard let (tableView, textView) = timer.userInfo as?
            (UITableView, UITextView) else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "timer.userInfo not defined correctly")
                return
        }
        self.scrollCaretToVisible(tableView: tableView, textView: textView)
    }
}
