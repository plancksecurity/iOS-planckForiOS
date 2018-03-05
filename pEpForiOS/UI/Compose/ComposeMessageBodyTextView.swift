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
                Timer.scheduledTimer(timeInterval: 0.01,
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

            // Extend the rectangle in both directions vertically,
            // to both include 1 line above and below.
            tvRect.origin.y -= tvRect.size.height
            tvRect.size.height *= 3

            containingTableView.scrollRectToVisible(tvRect, animated: false)
        }
    }

    fileprivate let newLinePaddingRegEx = try! NSRegularExpression(
        pattern: ".*[^\n]+(\n){2,}$", options: [])

    public override func addNewlinePadding() {
        if fieldModel?.type != .content {
            return
        }

        func paddedByDoubleNewline(pureText: NSAttributedString) -> Bool {
            let numMatches = newLinePaddingRegEx.numberOfMatches(
                in: pureText.string, options: [], range: pureText.wholeRange())
            return numMatches > 0
        }

        if text.isEmpty {
            return
        }

        var changed = false
        let theText = NSMutableAttributedString(attributedString: attributedText)
        let theRange = selectedRange

        //the text always must end with two \n
        while (!theText.string.endsWith("\n\n")) {
            let appendedString = NSMutableAttributedString(string: "\n")
            appendedString.addAttribute(NSAttributedStringKey.font,
                                        value: UIFont.pEpInput,
                                        range: appendedString.wholeRange()
            )

            theText.append(appendedString)
            changed = true
        }

        if changed {
            attributedText = theText
            selectedRange = theRange
        }
    }
}
