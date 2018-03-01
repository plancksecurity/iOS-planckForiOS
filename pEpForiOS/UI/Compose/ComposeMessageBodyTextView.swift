//
//  ComposeMessageBodyTextView.swift
//  pEp
//
//  Created by Dirk Zimmermann on 28.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class ComposeMessageBodyTextView: ComposeTextView {
    override func layoutAfterTextDidChange(tableView: UITableView) {
        tableView.updateSize() { [weak self] in
            if let theSelf = self {
                theSelf.scrollCaretToVisible(textView: theSelf, containingTableView: tableView)
            }
        }
    }

    /**
     Makes sure that the given text view's cursor (if any) is visible, given that it is
     contained in the given table view.
     */
    func scrollCaretToVisible(textView: UITextView, containingTableView: UITableView) {
        if let uiRange = textView.selectedTextRange, uiRange.isEmpty {
            let selectedRect = textView.caretRect(for: uiRange.end)
            let tvRect = containingTableView.convert(selectedRect, from: textView)
            containingTableView.scrollRectToVisible(tvRect, animated: false)
        }
    }
}
