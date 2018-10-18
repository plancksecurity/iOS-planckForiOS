//
//  RecipientTextViewModel.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol RecipientTextViewModelResultDelegate: class {

    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel,
                                didChangeRecipients newRecipients: [Identity])

    func recipientTextViewModelDidEndEditing(recipientTextViewModel: RecipientTextViewModel)

    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel,
                                textChanged newText: String)
}

protocol RecipientTextViewModelDelegate: class {
    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel,
                                didChangeAttributedText newText: NSAttributedString)

    func add(recipient: String)
}

class RecipientTextViewModel {
    var maxTextattachmentWidth: CGFloat = 0.0 // arbitrary value to avoid optional
    public private(set) var isDirty = false
    //    public var hasSelectedAttachment = false //IOS-1369: obsolete?
    private var recipientAttachments = [RecipientTextViewTextAttachment]() {
        didSet {
            let recipients = recipientAttachments.map { $0.recipient }
            resultDelegate?.recipientTextViewModel(recipientTextViewModel: self,
                                                   didChangeRecipients: recipients)
        }
    }

    public weak var resultDelegate: RecipientTextViewModelResultDelegate?
    public weak var delegate: RecipientTextViewModelDelegate?

    init(resultDelegate: RecipientTextViewModelResultDelegate? = nil) {
        self.resultDelegate = resultDelegate
    }

    public func add(recipient: Identity) {
        delegate?.add(recipient: recipient.address)
    }

    public func shouldInteract(WithTextAttachment attachment: NSTextAttachment) -> Bool {
        if let _ = attachment.image {
            // Suppress default image handling. Our recipient names are actually displayed as
            // images and we do not want to offer "save to camera roll" aciont sheet or other image
            // actions to the user.
            return false
        }
        return true
    }

    //IOS-1369: do we need that @all?
    public func handleDidEndEditing(range: NSRange,
                                    of text: NSAttributedString) {
        tryGenerateValidAddressAndUpdateStatus(range: range, of: text)
        resultDelegate?.recipientTextViewModelDidEndEditing(recipientTextViewModel: self)
    }

    public func handleTextChange(newText: String) {
        let textOnly = newText.trimObjectReplacementCharacters().trimmed()
        isDirty = !textOnly.isEmpty
        resultDelegate?.recipientTextViewModel(recipientTextViewModel: self, textChanged: textOnly)
    }

    public func isAddressDeliminator(str: String) -> Bool {
        return addressDeliminators.contains(str)
    }

    public func handleAddressDelimiterTyped(range: NSRange,
                                            of text: NSAttributedString) -> Bool {
        let valid = tryGenerateValidAddressAndUpdateStatus(range: range, of: text)
        resultDelegate?.recipientTextViewModelDidEndEditing(recipientTextViewModel: self)
        return valid
    }

    public func handleSelectedAttachment(_ attachments: [RecipientTextViewTextAttachment]) {
        for attachment in attachments {
            removeRecipientAttachment(attachment: attachment)
        }
    }

    private func removeRecipientAttachment(attachment: RecipientTextViewTextAttachment) {
        recipientAttachments = recipientAttachments
            .filter { $0.recipient.address != attachment.recipient.address }
    }

     @discardableResult private func tryGenerateValidAddressAndUpdateStatus(range: NSRange,
                                                        of text: NSAttributedString) -> Bool {
        let containsNothingButAttachments = text.plainTextRemoved().length == text.length
        let validEmailaddressHandled = parseAndHandleValidEmailAddresses(inRange: range, of: text)
        isDirty = !validEmailaddressHandled && !containsNothingButAttachments
        return validEmailaddressHandled
    }

    private var addressDeliminators: [String] {
        return [String.returnKey, String.space]
    }

    /// Parses a text for one new valid email address (and handles it if found).
    ///
    /// - Parameter text: Text thet might alread contain contact-image-text-attachments.
    /// - Returns: true if a valid address has been found, false otherwize
    @discardableResult private func parseAndHandleValidEmailAddresses(
        inRange range: NSRange, of text: NSAttributedString) -> Bool {
        var identityGenerated = false
        let stringWithoutTextAttachments = text.string.cleanAttachments
        if stringWithoutTextAttachments.isProbablyValidEmail() {
            let address = stringWithoutTextAttachments.trimmed()
            let identity: Identity
            if let existing = Identity.by(address: address) {
                identity = existing
            } else {
                identity = Identity.create(address: address)
            }
            var (newText, attachment) = text.imageInserted(withAddressOf: identity,
                                                           in: range,
                                                           maxWidth: maxTextattachmentWidth)
            recipientAttachments.append(attachment)
            newText = newText.plainTextRemoved()
            delegate?.recipientTextViewModel(recipientTextViewModel: self,
                                             didChangeAttributedText: newText)
            identityGenerated =  true
        }
        return identityGenerated
    }
}

// //COMPOSE TEXT VIEW
// public var fieldModel: ComposeFieldModel?
//
// private final var fontDescender: CGFloat = -7.0
// final var textBottomMargin: CGFloat = 25.0
//          // private final var imageFieldHeight: CGFloat = 66.0
//
// let scrollUtil = TextViewInTableViewScrollUtil()
//
// //IOS-1369: should (all?) go to UITextViewExtention
//
// public func insertImage(with text: String, maxWidth: CGFloat = 0.0) {
// let attrText = NSMutableAttributedString(attributedString: attributedText)
// let img = ComposeHelper.recepient(text, textColor: .pEpGreen, maxWidth: maxWidth - 20.0)
// let at = TextAttachment()
// at.image = img
// at.bounds = CGRect(x: 0, y: fontDescender, width: img.size.width, height: img.size.height)
// let attachString = NSAttributedString(attachment: at)
// attrText.replaceCharacters(in: selectedRange, with: attachString)
// attrText.addAttribute(NSAttributedStringKey.font,
// value: UIFont.pEpInput,
// range: NSRange(location: 0, length: attrText.length)
// )
// attributedText = attrText
// }
//
// public var fieldHeight: CGFloat {
// get {
// let size = sizeThatFits(CGSize(width: frame.size.width,
// height: CGFloat(Float.greatestFiniteMagnitude)))
// return size.height + textBottomMargin
// }
// }
//
// public func scrollToBottom() {
// if fieldHeight >= imageFieldHeight {
// setContentOffset(CGPoint(x: 0.0, y: fieldHeight - imageFieldHeight), animated: true)
// }
// }
//
// public func scrollToTop() {
// contentOffset = .zero
// }
//
// public func addNewlinePadding() {
// // Does nothing for recipient text views.
// }
//
// /**
// Invoke any actions needed after the text has changed, i.e. forcing the table to
// pick up the new size and scrolling to the current cursor position.
// */
// public func layoutAfterTextDidChange(tableView: UITableView) {
// // Does nothing for recipient text views.
// }
//
// func scrollCaretToVisible(tableView: UITableView) {
// scrollUtil.scrollCaretToVisible(tableView: tableView, textView: self)
// }

