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
    private var ccEnabled = false
    
    fileprivate var recipients = [Int]()
    fileprivate var hasSelection = false
    
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
    
    fileprivate func removeRecepients() {
        recipients.forEach({ (recepient: Int) in
            if identities[safe: recepient] != nil {
                identities.remove(at: recepient)
            }
        })
        if let fm = super.fieldModel {
            delegate?.haveToUpdateColor(newIdentity: identities, type: fm)
        }
    }

    @IBAction func openAdressbook(_ sender: UIButton) {
        guard let delegate = delegate as? RecipientCellDelegate else { return }
        delegate.shouldOpenAddressbook(at: index)
    }
}

// MARK: - UITextViewDelegate

extension RecipientCell {
    public override func textViewDidBeginEditing(_ textView: UITextView) {
        guard let cTextview = textView as? ComposeTextView else { return }

        delegate?.textdidStartEditing(at: index, textView: cTextview)
    }
    
    public override func textViewDidChange(_ textView: UITextView) {
        guard let cTextview = textView as? ComposeTextView else { return }
        
        recipients.removeAll()
        delegate?.textdidChange(at: index, textView: cTextview)
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
    
    public override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == .returnKey) {
            generateContact(textView)
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
        return true
    }

    fileprivate func generateContact(_ textView: UITextView) {
        guard let cTextview = textView as? ComposeTextView else { return }
        var string = cTextview.attributedText.string.cleanAttachments
        if string.utf8.count >= 3 && string.isEmailAddress {
            let identity = Identity.create(address: string.trimmedWhiteSpace())
            identities.append(identity)
            let width = self.textView.bounds.width
            cTextview.insertImage(identity, maxWidth: width)
            cTextview.removePlainText()
        }
        let text = cTextview.attributedText.string.cleanAttachments
        delegate?.messageCanBeSend(value: (identities.count > 0 && text.isEmpty))


        delegate?.textDidEndEditing(at: index, textView: cTextview)
        if let fm = super.fieldModel {
            delegate?.haveToUpdateColor(newIdentity: identities, type: fm)
        }
    }

    public override func textViewDidEndEditing(_ textView: UITextView) {

        generateContact(textView)

    }
}
