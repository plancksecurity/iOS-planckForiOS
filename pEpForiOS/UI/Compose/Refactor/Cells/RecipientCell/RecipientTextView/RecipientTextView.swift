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
    public var viewModel = RecipientTextViewModel() {
        didSet {
            delegate = self
        }
    }

    public func insertImage(with text: String, maxWidth: CGFloat = 0.0) {
        let attrText = NSMutableAttributedString(attributedString: attributedText)
        let img = ComposeHelper.recipient(text, textColor: .pEpGreen, maxWidth: maxWidth - 20.0)
        let at = TextAttachment()
        at.image = img
        let fontDescender: CGFloat = -7.0
        at.bounds = CGRect(x: 0, y: fontDescender, width: img.size.width, height: img.size.height)
        let attachString = NSAttributedString(attachment: at)
        attrText.replaceCharacters(in: selectedRange, with: attachString)
        attrText.addAttribute(NSAttributedStringKey.font,
                              value: UIFont.pEpInput,
                              range: NSRange(location: 0, length: attrText.length)
        )
        attributedText = attrText
    }

}

// MARK: - UITextViewDelegate

extension RecipientTextView: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
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
            let result = generateContact(textView)
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

    @discardableResult func generateContact(_ textView: UITextView) -> Bool {
        guard let cTextview = textView as? ComposeTextView else {
            Log.shared.errorAndCrash(component: #function, errorString: "Error casting")
            return false
        }
        var mail = false
        let string = cTextview.attributedText.string.cleanAttachments
        if string.isProbablyValidEmail() {
            let identity = Identity.create(address: string.trimmed())
            identities.append(identity)
            let width = self.textView.bounds.width
            cTextview.insertImage(with: identity.displayString, maxWidth: width)
            cTextview.attributedText = cTextview.attributedText.plainTextRemoved()
            mail =  true
        }
        delegate?.textDidEndEditing(at: index, textView: cTextview)
        if let fm = super.fieldModel {
            delegate?.composeCell(cell: self, didChangeEmailAddresses: identities.map{ $0.address }, forFieldType: fm.type)
        }
        return mail
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
        return textView.attributedText.string.trimObjectReplacementCharacters() == ""
    }

    public override func textViewDidEndEditing(_ textView: UITextView) {
        viewModel.handleDidEndEditing()
        let _ = generateContact(textView)
    }

    //IOS-1369:  !! DONE !!

    func textView(_ textView: UITextView,
                  shouldInteractWith textAttachment: NSTextAttachment,
                  in characterRange: NSRange) -> Bool {
        return viewModel.shouldInteract(WithTextAttachment: textAttachment)
    }
}
