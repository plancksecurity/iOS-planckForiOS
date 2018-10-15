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
}

protocol RecipientTextViewModelDelegate: class {
    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel,
                                didChangeAttributedText newText: NSAttributedString)
}

class RecipientTextViewModel {
    var maxTextattachmentWidth: CGFloat = 0.0 // arbitrary value to avoid optional
    private var isDirty = false
    private var identities = [Identity]() {
        didSet {
            resultDelegate?.recipientTextViewModel(recipientTextViewModel: self,
                                                   didChangeRecipients: identities)
        }
    }

    public weak var resultDelegate: RecipientTextViewModelResultDelegate?
    public weak var delegate: RecipientTextViewModelDelegate?

    init(resultDelegate: RecipientTextViewModelResultDelegate? = nil) {
        self.resultDelegate = resultDelegate
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

    public func handleDidEndEditing(range: NSRange,
                                    of text: NSAttributedString) {
        let validEmailaddressHandled = parseAndHandleValidEmailAddresses(inRange: range, of: text)
        isDirty = !validEmailaddressHandled
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
            let identity = Identity.create(address: stringWithoutTextAttachments.trimmed())
            identities.append(identity)
            var newText = text.imageInserted(with: identity.displayString,
                                             in: range,
                                             maxWidth: maxTextattachmentWidth)
            newText = newText.plainTextRemoved()
            delegate?.recipientTextViewModel(recipientTextViewModel: self,
                                             didChangeAttributedText: newText)
            identityGenerated =  true
        }
        resultDelegate?.recipientTextViewModelDidEndEditing(recipientTextViewModel: self)
        //        delegate?.textDidEndEditing(at: index, textView: cTextview)//IOS-1369: //!!!
        /*
         ->
         func textDidEndEditing(at indexPath: IndexPath, textView: ComposeTextView) {
         tableView.updateSize()
         hideSuggestions()
         }
         */
        //        if let fm = super.fieldModel {
        //            delegate?.composeCell(cell: self, didChangeEmailAddresses: identities.map{ $0.address }, forFieldType: fm.type) //IOS-1369: //!!!:
        /*
         ->
         func composeCell(cell: ComposeCell, didChangeEmailAddresses changedAddresses: [String],
         forFieldType type: ComposeFieldModel.FieldType) {
         let identities = changedAddresses.map { Identity.by(address: $0) ?? Identity(address: $0) }
         switch type {
         case .to:
         destinyTo = identities
         case .cc:
         destinyCc = identities
         case .bcc:
         destinyBcc = identities
         case .from:
         origin = identities.last
         default:
         break
         }
         calculateComposeColorAndInstallTapGesture()
         recalculateSendButtonStatus()
         }*/
        //        }
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

