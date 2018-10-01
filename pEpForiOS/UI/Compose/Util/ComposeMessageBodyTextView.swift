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
        sizeToFit()
        scrollUtil.layoutAfterTextDidChange(tableView: tableView, textView: self)
    }

    private let newLinePaddingRegEx = try! NSRegularExpression(
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
