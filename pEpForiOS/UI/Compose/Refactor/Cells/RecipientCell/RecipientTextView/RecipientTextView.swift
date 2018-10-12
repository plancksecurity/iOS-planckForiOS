//
//  RecipientTextView.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientTextView: UITextView {
    //IOS-1369: TODO:
    public var viewModel: RecipientTextViewModel?{
        didSet {
            viewModel?.delegate = self
            delegate = self
        }
    }
}

// MARK: - UITextViewDelegate

extension RecipientTextView: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
        viewModel?.maxTextattachmentWidth = bounds.width
//        guard let cTextview = textView as? ComposeTextView else { return }
//
//        delegate?.textDidStartEditing(at: index, textView: cTextview)
        /*
         ->
         func textDidStartEditing(at indexPath: IndexPath, textView: ComposeTextView) {
         // do nothing
         }
         */
    }

    public func textViewDidChange(_ textView: UITextView) {
//        guard let cTextview = textView as? ComposeTextView else { return }
//
//        recipients.removeAll()
//        delegate?.textDidChange(at: index, textView: cTextview)

    }

    /*
 //IOS-1369: Next !!


    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let cTextview = textView as? ComposeTextView else { return }

        if textView.selectedRange.location != NSNotFound, let range = textView.selectedTextRange {
            let selected = textView.text(in: range)

            // Extract text attachments form selection
            if let theSelected = selected {
                let attachments = cTextview.attributedText.textAttachments(string: theSelected)
                if attachments.count > 0 {
                    recipients.append(textView.selectedRange.location)
                }
            }
        }
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                                  replacementText text: String) -> Bool {
        if (text == .returnKey || text == .space) {
            let result = generateContact()
            return result
        }

        if text.utf8.count == 0 && range.location != NSNotFound && !hasSelection {
            let selectedRange = textView.selectedTextRange!

            if let newPos = textView.position(from: selectedRange.start, offset: -1) {
                let newRange = textView.textRange(from: newPos, to: selectedRange.start)

                // Check if text is Attachment and select it
                if textView.text(in: newRange!)!.isAttachment {
                    textView.selectedTextRange = newRange
                    hasSelection = true
                    return false
                }
            }
        }

        if range.location != NSNotFound {
            removeRecepients()
        }

        hasSelection = false

        let last = textView.text.last
        if "\n" == last && text == "\n" {
            return false
        }

        return true
    }

    /// Wheter or not textView.attributedText.string is empty after removing all attachments
    var containsNothingButValidAddresses: Bool {
        // Only addresses that became an attachment are considered valid ...
        let allButValidAddresses = textView.attributedText.string.cleanAttachments
        // ... thus, if we remove all attachments, there should be nothing left.
        return allButValidAddresses.trimObjectReplacementCharacters() == ""
    }

    /// Wheter or not textView.attributedText.string is considered empty.
    var isEmpty: Bool {
        // UITextView places this character if you delete an attachment, which leads to a
        // non-empty string.
        return self.attributedText.string.trimObjectReplacementCharacters() == ""
    }
     //IOS-1369: Next !!
 */

    //IOS-1369: WIP
    public func textViewDidEndEditing(_ textView: UITextView) {
        viewModel?.handleDidEndEditing(range: textView.selectedRange, of: textView.attributedText)
    }

    //IOS-1369:  !! DONE !!

    func textView(_ textView: UITextView,
                  shouldInteractWith textAttachment: NSTextAttachment,
                  in characterRange: NSRange) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return true
        }
        return vm.shouldInteract(WithTextAttachment: textAttachment)
    }
}

extension RecipientTextView: RecipientTextViewModelDelegate {
    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel,
                                didChangeAttributedText newText: NSAttributedString) {
        self.attributedText = newText
    }
}
