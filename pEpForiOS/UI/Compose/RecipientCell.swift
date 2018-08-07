//
//  RecipientCell.swift
//  pEpForiOS
//
//  Created by Yves Landert on 11/3/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import Contacts
import MessageModel

class RecipientCell: ComposeCell {
    @IBOutlet weak var addButton: UIButton!
    public var identities = [Identity]()
    var ccEnabled = false
    
    private var recipients = [Int]()
    private var hasSelection = false
    
    override open func awakeFromNib() {
        selectionStyle = .none
    }
    
    public func addIdentity(_ identity: Identity) {
        identities.append(identity)
        let width = self.textView.bounds.width
        textView.insertImage(identity, true, maxWidth: width)
        textView.removePlainText()
        if let fm = super.fieldModel {
            delegate?.haveToUpdateColor(newIdentity: identities, type: fm)
        }
    }

    private func removeRecepients() {
        recipients.forEach({ (recepient: Int) in
            if identities[safe: recepient] != nil {
                identities.remove(at: recepient)
            }
        })
        if let fm = super.fieldModel {
            delegate?.haveToUpdateColor(newIdentity: identities, type: fm)
        }
    }

    // MARK: - Public Methods

    override func shouldDisplay()-> Bool {
        return fieldModel?.display == .always || ccEnabled
    }
}

// MARK: - UITextViewDelegate

extension RecipientCell {
    public override func textViewDidBeginEditing(_ textView: UITextView) {
        guard let cTextview = textView as? ComposeTextView else { return }

        delegate?.textDidStartEditing(at: index, textView: cTextview)
    }
    
    override public func textViewDidChange(_ textView: UITextView) {
        guard let cTextview = textView as? ComposeTextView else { return }
        
        recipients.removeAll()
        delegate?.textDidChange(at: index, textView: cTextview)
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let cTextview = textView as? ComposeTextView else { return }
        
        if textView.selectedRange.location != NSNotFound, let range = textView.selectedTextRange {
            let selected = textView.text(in: range)
            
            // Extract text attachments form selection
            if let theSelected = selected {
                let attachments = cTextview.textAttachments(string: theSelected)
                if attachments.count > 0 {
                    recipients.append(textView.selectedRange.location)
                }
            }
        }
    }
    
    public override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                                  replacementText text: String) -> Bool {
        if (text == .returnKey) {
            let result = generateContact(textView)
            return result
        }

        //enable send button when there are something in recipents and disable it if its empty
        delegate?.messageCanBeSend(value: !(
            (textView.text.isEmpty || text.isEmpty)
                &&
            (range.length == 1 && !(range.location > 0))))
        
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

    @discardableResult  func generateContact(_ textView: UITextView) -> Bool {
        guard let cTextview = textView as? ComposeTextView else { return false }
        var mail = false
        var string = cTextview.attributedText.string.cleanAttachments
        if string.utf8.count >= 3 && string.isEmailAddress {
            let identity = Identity.create(address: string.trimmedWhiteSpace())
            identities.append(identity)
            let width = self.textView.bounds.width
            cTextview.insertImage(identity, maxWidth: width)
            cTextview.removePlainText()
            mail =  true
        }

        delegate?.textDidEndEditing(at: index, textView: cTextview)

        if let fm = super.fieldModel {
            delegate?.haveToUpdateColor(newIdentity: identities, type: fm)
        }

        return mail
    }

    public override func textViewDidEndEditing(_ textView: UITextView) {
        let _ = generateContact(textView)
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange) -> Bool {
        if let _ = textAttachment.image {
            // Suppress default image handling. Our recipient names are actually displayed as
            // images and we do not want to offer "save to camera roll" aciont sheet or other image
            // actions.
            return false
        }
        return true
    }
}
