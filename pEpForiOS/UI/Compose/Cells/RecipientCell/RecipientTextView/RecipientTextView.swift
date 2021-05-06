//
//  RecipientTextView.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class RecipientTextView: UITextView {
    public var viewModel: RecipientTextViewModel? {
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
        if let attr = viewModel?.inititalText(), attr.string != "" {
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
        setLabelTextColor()
        viewModel?.handleDidBeginEditing(text: textView.text)
    }

    public func textViewDidChange(_ textView: UITextView) {
        viewModel?.handleTextChange(newText: textView.text, newAttributedText: attributedText)
    }

    public func textView(_ textView: UITextView,
                         shouldChangeTextIn range: NSRange,
                         replacementText text: String) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return true
        }
        if vm.isAddressDeliminator(str: text) {
            let result = vm.handleAddressDelimiterTyped(range: range, of: textView.attributedText)
            setLabelTextColor()
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
                Log.shared.errorAndCrash("Invalid state")
                return true
            }
            // Check if text is Attachment and select it
            if potentiallyReplacedText.isAttachment {
                textView.selectedTextRange = newRange
                return false
            }
        } else if hasSelection {
            // user deleted a selected attachment
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
            Log.shared.errorAndCrash("No VM")
            return true
        }
        return vm.shouldInteract(with: textAttachment)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

        // Sometimes Paste menu item doesn't appear. This is workaround for this.
        if action == #selector(UIResponderStandardEditActions.paste(_:))
            && UIPasteboard.general.hasStrings {
            return true
        }

        guard let customItems: [UIMenuItem] = UIMenuController.shared.menuItems else {
            return super.canPerformAction(action, withSender: sender)
        }
        let actions = customItems.map { $0.action }
        if actions.contains(action) {
            return true
        }

        return super.canPerformAction(action, withSender: sender)
    }

    override func cut(_ sender: Any?) {
        addSelectedEmailsToClipboard()
        let attributedStringSelectedTextToCut = NSMutableAttributedString(attributedString: attributedText)
        attributedStringSelectedTextToCut.deleteCharacters(in: selectedRange)
        attributedText = NSAttributedString(attributedString: attributedStringSelectedTextToCut)
    }

    override func copy(_ sender: Any?) {
        addSelectedEmailsToClipboard()
    }

    override func paste(_ sender: Any?) {
        guard UIPasteboard.general.hasStrings,
            let items = UIPasteboard.general.strings else {
            // Nothing to do in our case, no items, no more care about it
            return
        }
        items.forEach { add(recipient: $0) }
    }


    /// Get text attachments from selected text and copy recipients email addresses to Pasteboard/Clipboard
    private func addSelectedEmailsToClipboard() {
        let selection = attributedText.recipientTextAttachments(range: selectedRange)
        if selection.isEmpty {
            // Text attachments with recipients not found. We should stop here. No more actions on Pasteboard is needed
            return
        }
        UIPasteboard.general.strings = [String]()
        selection
            .filter { !$0.recipient.address.isEmpty }
            .forEach { UIPasteboard.general.strings?.append($0.recipient.address) }
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        /// iOS 14 introduced a bug: it's not possible to focus the textfield when there is an attachment.
        /// Instead of calling the begin editing delegate of the textfield this method is called.
        /// So we just trigger the focus manually.
        /// For more information please go to https://pep.foundation/jira/browse/IOS-2472
        if #available(iOS 14, *) {
            textView.selectedRange = NSRange(location: viewModel?.numberOfRecipientAttachments ?? 1, length: 0)
            textView.becomeFirstResponder()
        }
        return true
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
        if #available(iOS 13.0, *) {
            textColor = .label
        } else {
            // Fallback on earlier versions: nothing to do.
        }
    }
}
