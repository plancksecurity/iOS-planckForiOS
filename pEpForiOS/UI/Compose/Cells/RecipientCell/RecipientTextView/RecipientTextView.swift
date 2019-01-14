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
            text = " "
        }
    }
}

// MARK: - UITextViewDelegate

extension RecipientTextView: UITextViewDelegate {

    public func textViewDidBeginEditing(_ textView: UITextView) {
        reportWidthChange()
        viewModel?.handleDidBeginEditing(text: textView.text)
    }

    public func textViewDidChange(_ textView: UITextView) {
        viewModel?.handleTextChange(newText: textView.text, newAttributedText: attributedText)
    }

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
        guard let vm = viewModel else {
            Logger.frontendLogger.errorAndCrash("No VM")
            return true
        }
        if vm.isAddressDeliminator(str: text) {
            let result = vm.handleAddressDelimiterTyped(range: range, of: textView.attributedText)
            return result
        }
        let hasSelection = !(selectedTextRange?.isEmpty ?? true)
        if text.utf8.count == 0 && range.location != NSNotFound && !hasSelection {
            guard
                let selectedRange = textView.selectedTextRange,
                let newPos = textView.position(from: selectedRange.start, offset: -1),
                let newRange = textView.textRange(from: newPos, to: selectedRange.start) else {
                    return true
            }
            guard let potentiallyReplacedText = textView.text(in: newRange) else {
                Logger.frontendLogger.errorAndCrash("Invalid state")
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
            Logger.frontendLogger.errorAndCrash("No VM")
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
