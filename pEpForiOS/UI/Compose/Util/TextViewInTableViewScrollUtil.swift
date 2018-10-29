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
    //IOS-1369: Assume obsolete
    typealias Height = NSNumber
    //IOS-1369: Assume obsolete
    /// Caches height for TextView.
    private var sizeCache = NSMapTable<UITextView, Height>(keyOptions: .weakMemory,
                                                           valueOptions: .strongMemory)
//IOS-1369: Assume obsolete
    func layoutAfterTextDidChange(tableView: UITableView, textView: UITextView) {
        if heightDidChange(for: textView) {
            tableView.updateSize()
        }
        self.scrollCaretToVisible(tableView: tableView, textView: textView)
    }

    //IOS-1369: Assume obsolete
    /**
     Makes sure that the given text view's cursor (if any) is visible, given that it is
     contained in the given table view.
     */
    func scrollCaretToVisible(tableView: UITableView, textView: UITextView) {
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

    //IOS-1369: Assume obsolete
    /// Tracks text view heights.
    ///
    /// - Parameter textView: text view to check
    /// - Returns:  true if given textView is not known yet or it's height did change since last the
    ///             call, false otherwize
    private func heightDidChange(for textView: UITextView) -> Bool {
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
}
