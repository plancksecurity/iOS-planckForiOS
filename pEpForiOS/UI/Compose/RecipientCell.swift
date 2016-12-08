//
//  RecipientCell.swift
//  pEpForiOS
//
//  Created by Yves Landert on 11/3/16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import Contacts

public struct Recipient {
    
    var email: String!
    var name: String?
    var contact: CNContact?
}


class RecipientCell: ComposeCell {
    
    @IBOutlet weak var addButton: UIButton!
    
    public var addresses = [Recipient]()
    private var ccEnabled = false
    
    fileprivate var recipients = [Int]()
    fileprivate var hasSelection = false
    
    override open func awakeFromNib() {
        selectionStyle = .none
        addButton.isHidden = true
    }
    
    public func addContact(_ contact: CNContact) {
        let recipient = Recipient(email: contact.firstEmail, name: contact.fullname, contact: contact)
        addresses.append(recipient)
        
        textView.insertImage(contact.fullname)
        textView.removePlainText()
    }
    
    fileprivate func removeRecepients() {
        recipients.forEach({ (recepient: Int) in
            if addresses.isSafe(recepient) != nil {
                addresses.remove(at: recepient)
            }
        })
    }
    
    @IBAction func openAdressbook(_ sender: UIButton) {
        guard let delegate = delegate as? RecipientCellDelegate else { return }
        delegate.shouldOpenAddressbook(at: index)
    }
}

// MARK: - UITextViewDelegate

extension RecipientCell {
    
    public override func textViewDidBeginEditing(_ textView: UITextView) {
        guard let cmTextview = textView as? ComposeTextView else { return }
        
        addButton.isHidden = false
        delegate?.textdidStartEditing(at: index, textView: cmTextview)
    }
    
    public override func textViewDidChange(_ textView: UITextView) {
        guard let cmTextview = textView as? ComposeTextView else { return }
        
        recipients.removeAll()
        delegate?.textdidChange(at: index, textView: cmTextview)
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let cmTextview = textView as? ComposeTextView else { return }
        
        if textView.selectedRange.length > 0 {
            let range = textView.selectedTextRange!
            let selected = textView.text(in: range)
            
            // Extract text attachments form selection
            let attachments = cmTextview.getAttachments(selected!)
            if attachments.count > 0 {
                recipients.append(textView.selectedRange.location)
            }
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == .returnKey) {
            guard let cmTextview = textView as? ComposeTextView else { return false }
            delegate?.textShouldReturn(at: index, textView: cmTextview)
            return false
        }
        
        if text.characters.count == 0 && range.length > 0 && !hasSelection {
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
        
        if range.length > 0 {
            removeRecepients()
        }
        
        hasSelection = false
        return true
    }
    
    public override func textViewDidEndEditing(_ textView: UITextView) {
        guard let cmTextview = textView as? ComposeTextView else { return }
        
        var string = cmTextview.attributedText.string.cleanAttachments
        if string.characters.count >= 3 {
            addresses.append(Recipient(email: string, name: nil, contact: nil))
            cmTextview.insertImage(string)
            cmTextview.removePlainText()
        }
        
        addButton.isHidden = cmTextview.text.isEmpty
        delegate?.textDidEndEditing(at: index, textView: cmTextview)
    }
    
}
