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
    private struct MyUserInfo {
        let textView: UITextView
        let tableView: UITableView
    }

    override func layoutAfterTextDidChange(tableView: UITableView) {
        tableView.updateSize() { [weak self] in
            if let theSelf = self {
                Timer.scheduledTimer(timeInterval: 0.1,
                                     target: theSelf,
                                     selector: #selector(theSelf.timerScroll),
                                     userInfo: MyUserInfo(textView: theSelf, tableView: tableView),
                                     repeats: false)
            }
        }
    }

    @objc func timerScroll(_ timer: Timer) {
        if let info = timer.userInfo as? MyUserInfo {
            self.scrollCaretToVisible(textView: info.textView,
                                      containingTableView: info.tableView)
        }
    }

    /**
     Makes sure that the given text view's cursor (if any) is visible, given that it is
     contained in the given table view.
     */
    func scrollCaretToVisible(textView: UITextView, containingTableView: UITableView) {
        if let uiRange = textView.selectedTextRange, uiRange.isEmpty {
            let selectedRect = textView.caretRect(for: uiRange.end)
            var tvRect = containingTableView.convert(selectedRect, from: textView)

            // move the rect a little further, to give space below
            tvRect.origin.y += tvRect.size.height

            containingTableView.scrollRectToVisible(tvRect, animated: false)
        }
    }
}
