//
//  RecipientTextViewModel.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

public protocol RecipientTextViewModelResultDelegate: class {

    func recipientTextViewModel(_ vm: RecipientTextViewModel,
                                didChangeRecipients newRecipients: [Identity])

    func recipientTextViewModel(_ vm: RecipientTextViewModel, didBeginEditing text: String)

    func recipientTextViewModelDidEndEditing(_ vm: RecipientTextViewModel)

    func recipientTextViewModel(_ vm: RecipientTextViewModel, textChanged newText: String)
}

public protocol RecipientTextViewModelDelegate: class {
    
    func textChanged(newText: NSAttributedString)

    func add(recipient: String)
}

public class RecipientTextViewModel {
    var maxTextattachmentWidth: CGFloat = 0.0
    private var initialRecipients = [Identity]()
    private var attributedText: NSAttributedString?
    public private(set) var isDirty = false
    private var recipientAttachments = [TextAttachment]() {
        didSet {
            let recipients = recipientAttachments.map { $0.recipient }
            resultDelegate?.recipientTextViewModel(self,
                                                   didChangeRecipients: recipients)
        }
    }

    public weak var resultDelegate: RecipientTextViewModelResultDelegate?
    public weak var delegate: RecipientTextViewModelDelegate?

    init(resultDelegate: RecipientTextViewModelResultDelegate? = nil, recipients: [Identity] = []) {
        self.resultDelegate = resultDelegate
        self.initialRecipients = recipients
    }

    public func inititalText() -> NSAttributedString? {
        if attributedText == nil {
            setupInitialText()
        }
        isDirty = false
        return attributedText
    }

    public func add(recipient: Identity) {
        delegate?.add(recipient: recipient.address)
    }

    public func shouldInteract(with textAttachment: NSTextAttachment) -> Bool {
        if let _ = textAttachment.image {
            // Suppress default image handling. Our recipient names are actually displayed as
            // images and we do not want to offer "save to camera roll" aciont sheet or other image
            // actions to the user.
            return false
        }
        return true
    }

    public func handleDidBeginEditing(text: String) {
        resultDelegate?.recipientTextViewModel(self, didBeginEditing: text)
    }

    public func handleDidEndEditing(range: NSRange, of text: NSAttributedString) {
        attributedText = text
        tryGenerateValidAddressAndUpdateStatus(range: range, of: text)
        resultDelegate?.recipientTextViewModelDidEndEditing(self)
    }

    public func handleTextChange(newText: String, newAttributedText: NSAttributedString) {
        attributedText = newAttributedText
        let textOnly = newText.trimObjectReplacementCharacters().trimmed()
        isDirty = !textOnly.isEmpty
        resultDelegate?.recipientTextViewModel(self, textChanged: textOnly)
    }

    public func isAddressDeliminator(str: String) -> Bool {
        return addressDeliminators.contains(str)
    }

    public func handleAddressDelimiterTyped(range: NSRange,
                                            of text: NSAttributedString) -> Bool {
        let valid = tryGenerateValidAddressAndUpdateStatus(range: range, of: text)
        return valid
    }

    public func handleReplaceSelectedAttachments(_ attachments: [TextAttachment]) {
        for attachment in attachments {
            removeRecipientAttachment(attachment: attachment)
        }
    }

    private func removeRecipientAttachment(attachment: TextAttachment) {
        var copy = recipientAttachments
        /// In case there are more than one recipient with the same email address the deletion is only on one of them.
        if let index = copy.firstIndex(where: { $0.recipient.address == attachment.recipient.address }) {
            copy.remove(at: index)
            self.recipientAttachments = copy
        }
    }

     @discardableResult private func tryGenerateValidAddressAndUpdateStatus(range: NSRange,
                                                                            of text: NSAttributedString) -> Bool {
        let containsNothingButAttachments =
            text.plainTextRemoved().length == text.length ||
                text.plainTextRemoved().string.trimObjectReplacementCharacters().isEmpty
        let validEmailaddressHandled = parseAndHandleValidEmailAddresses(inRange: range, of: text)
        isDirty = !validEmailaddressHandled && !containsNothingButAttachments
        return validEmailaddressHandled
    }

    private var addressDeliminators: [String] {
        return [String.returnKey, String.space]
    }

    /// Returns the number of recipient attachments
    public var numberOfRecipientAttachments: Int {
        return recipientAttachments.count
    }

    /// Parses a text for one new valid email address (and handles it if found).
    ///
    /// - Parameter text: Text thet might alread contain contact-image-text-attachments.
    /// - Returns: true if a valid address has been found, false otherwize
    @discardableResult private func parseAndHandleValidEmailAddresses(
        inRange range: NSRange, of text: NSAttributedString, informDelegate: Bool = true) -> Bool {
        var identityGenerated = false
        let stringWithoutTextAttachments = text.string.cleanAttachments
        if stringWithoutTextAttachments.isProbablyValidEmail() {
            let address = stringWithoutTextAttachments.trimmed()
            let identity: Identity
            if let existing = Identity.by(address: address) {
                identity = existing
            } else {
                identity = Identity(address: address)
                identity.session.commit()
            }
            var (newText, attachment) = text.imageInserted(withAddressOf: identity,
                                                           in: range,
                                                           maxWidth: maxTextattachmentWidth)
            recipientAttachments.append(attachment)

            newText = newText.plainTextRemoved()
            newText = newText.baselineOffsetRemoved()
            attributedText = newText

            if informDelegate {
                delegate?.textChanged(newText: newText)
            }
            identityGenerated =  true
        }
        return identityGenerated
    }

    private func setupInitialText() {

        for recipient in initialRecipients {
             let textBuilder =
                NSMutableAttributedString(attributedString: attributedText ?? NSAttributedString())
            let range = NSRange(location: max(textBuilder.length, 0),
                                length: 0)
            textBuilder.append(NSAttributedString(string: .space))
            textBuilder.append(NSAttributedString(string: recipient.address))

            parseAndHandleValidEmailAddresses(inRange: range,
                                              of: textBuilder,
                                              informDelegate: false)
        }
    }
}


