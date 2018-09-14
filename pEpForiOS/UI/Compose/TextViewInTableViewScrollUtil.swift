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
    typealias Height = NSNumber
    private var sizeCache = NSMapTable<UITextView, Height>(keyOptions: .weakMemory,
                                                           valueOptions: .strongMemory)

    func layoutAfterTextDidChange(tableView: UITableView, textView: UITextView) {
        textView.sizeToFit()
        self.scrollCaretToVisible(tableView: tableView, textView: textView)

        if checkCacheForChange(for: textView) {
            tableView.updateSize()
        }
    }

    //IOS-1317:
    private func checkCacheForChange(for textView: UITextView) -> Bool {
        defer {
            sizeCache.setObject(Height(value: Double(textView.frame.size.height)),
                                forKey: textView)
        }
        var sizeChanged = true
        guard let lastHeight = sizeCache.object(forKey: textView)?.doubleValue else {
            // Not cached yet, so yes.
            return sizeChanged
        }
        let newHeight = Double(textView.frame.size.height)
        if lastHeight == newHeight {
            sizeChanged = false
        }

        return sizeChanged
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
}
