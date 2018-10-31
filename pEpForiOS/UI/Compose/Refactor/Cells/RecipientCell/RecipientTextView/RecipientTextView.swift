//
//  RecipientTextView.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientTextView: UITextView {
    public var viewModel: RecipientTextViewModel?{
        didSet {
            viewModel?.delegate = self
            delegate = self
        }
    }

    private func reportWidthChange() {
        viewModel?.maxTextattachmentWidth = bounds.width
    }

    public func setInitialText() {
        reportWidthChange()
        if let attr = viewModel?.inititalText() {
            attributedText = attr
        } else {
            text = " " //IOS-1369: rm after setup. See subject
        }
    }
}

// MARK: - UITextViewDelegate

extension RecipientTextView: UITextViewDelegate {

    public func textViewDidBeginEditing(_ textView: UITextView) {
        reportWidthChange()
        viewModel?.handleDidBeginEditing(text: textView.text)
        //IOS-1369: scroll? suggestions?
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
        viewModel?.handleTextChange(newText: textView.text, newAttributedText: attributedText)
        //IOS-1369: scroll? suggestions?
//        guard let cTextview = textView as? ComposeTextView else { return }
//
//        recipients.removeAll()
//        delegate?.textDidChange(at: index, textView: cTextview)

    }

    /*
 //IOS-1369: Next !!

     //IOS-1369: maybe obsolete due to isDirty
                /// Wheter or not textView.attributedText.string is empty after removing all attachments
                var containsNothingButValidAddresses: Bool {
                    // Only addresses that became an attachment are considered valid ...
                    let allButValidAddresses = textView.attributedText.string.cleanAttachments
                    // ... thus, if we remove all attachments, there should be nothing left.
                    return allButValidAddresses.trimObjectReplacementCharacters() == ""
                }

     //IOS-1369: maybe obsolete due to known addresses
                /// Wheter or not textView.attributedText.string is considered empty.
                var isEmpty: Bool {
                    // UITextView places this character if you delete an attachment, which leads to a
                    // non-empty string.
                    return self.attributedText.string.trimObjectReplacementCharacters() == ""
                }
 */

    //IOS-1369: As far as I can see, this is obsolete, as we do not remomber the recipient text
    //          locations any more. Lets see how that works out.
                //    public func textViewDidChangeSelection(_ textView: UITextView) {
                //        guard let cTextview = textView as? ComposeTextView else { return }
                //
                //        if textView.selectedRange.location != NSNotFound, let range = textView.selectedTextRange {
                //            let selected = textView.text(in: range)
                //
                //            // Extract text attachments form selection
                //            if let theSelected = selected {
                //                let attachments = cTextview.attributedText.textAttachments(string: theSelected)
                //                if attachments.count > 0 {
                //                    recipients.append(textView.selectedRange.location)
                //                }
                //            }
                //        }
                //    }

    //IOS-1369: DONE

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return true
        }
        if vm.isAddressDeliminator(str: text) {
            let result = vm.handleAddressDelimiterTyped(range: range, of: textView.attributedText)
            return result
        }
        //IOS-1369: looks over complicated. Double check. See body cell 
        let hasSelection = !(selectedTextRange?.isEmpty ?? true)
        if text.utf8.count == 0 && range.location != NSNotFound && !hasSelection {
            guard
                let selectedRange = textView.selectedTextRange,
                let newPos = textView.position(from: selectedRange.start, offset: -1),
                let newRange = textView.textRange(from: newPos, to: selectedRange.start) else {
                    return true
            }
            guard let potentiallyReplacedText = textView.text(in: newRange) else {
                Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                return true
            }
            // Check if text is Attachment and select it
            if potentiallyReplacedText.isAttachment {
                textView.selectedTextRange = newRange
                return false
            }
        } else if hasSelection {
            // user deletes a selected attachment
            let attachments = attributedText.recipientTextAttachments(range: selectedRange)
            vm.handleReplaceSelectedAttachments(attachments)
            return true
        }
        return true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        viewModel?.handleDidEndEditing(range: textView.selectedRange, of: textView.attributedText)
    }

    func textView(_ textView: UITextView,
                  shouldInteractWith textAttachment: NSTextAttachment,
                  in characterRange: NSRange) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return true
        }
        return vm.shouldInteract(with: textAttachment)
    }
}

// MARK: - RecipientTextViewModelDelegate

extension RecipientTextView: RecipientTextViewModelDelegate {

    func textChanged(newText: NSAttributedString) {
        attributedText = newText
    }

    func add(recipient: String) {
        attributedText = attributedText.plainTextRemoved()
        let createe = NSMutableAttributedString(attributedString: attributedText)
        createe.append(NSAttributedString(string: recipient))
        attributedText = NSAttributedString(attributedString: createe)
        viewModel?.handleDidEndEditing(range: selectedRange, of: attributedText)
    }
}
