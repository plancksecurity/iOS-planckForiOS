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
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

public protocol RecipientTextViewModelResultDelegate: AnyObject {

    /// Communicate the recipients have changed.
    ///
    /// - Parameters:
    ///   - vm: The Recipient text view model.
    ///   - newRecipients: The new recipients in the text view model.
    ///   - hiddenRecipients: The hidden recipients. This is UI state only. They are the collapsed recipients.
    func recipientTextViewModel(_ vm: RecipientTextViewModel,
                                didChangeRecipients newRecipients: [Identity],
                                hiddenRecipients: [Identity]?)

    func recipientTextViewModel(_ vm: RecipientTextViewModel, didBeginEditing text: String)

    func recipientTextViewModelDidEndEditing(_ vm: RecipientTextViewModel)

    func recipientTextViewModel(_ vm: RecipientTextViewModel, textChanged newText: String)
}

public protocol RecipientTextViewModelDelegate: AnyObject {

    /// Remove the badge text attachments from the text view, if exists. Otherwise it does nothing.
    func removeBadgeTextAttachments()

    /// Remove the given recipients text attachments from the text view
    ///
    /// - Parameters:
    ///   - recipients: The Recipients text attachments to remove
    func removeRecipientsTextAttachments(recipients: [RecipientTextViewModel.TextAttachment])

    ///  Verify if there is space for a new text attachment in the row.
    ///
    /// - Parameters:
    ///   - recipientsTextAttachmentWidth: The accumulated width. This is the summatory of the width of all the recipients text attachments in the text view.
    ///   - expectedWidthOfTheNewTextAttachment: The recipient text attachment expected width.
    func isThereSpaceForANewTextAttachment(recipientsTextAttachmentWidth: CGFloat, expectedWidthOfTheNewTextAttachment: CGFloat) -> Bool

    func textChanged(newText: NSAttributedString)

    func add(recipient: String)
}

public class RecipientTextViewModel {
    var maxTextattachmentWidth: CGFloat = 0.0
    private var initialRecipients = [Identity]()
    private var attributedText: NSAttributedString?
    public private(set) var isDirty: Bool = false
    private var recipientAttachments = [TextAttachment]() {
        didSet {
            let recipients = recipientAttachments.map { $0.recipient }
            resultDelegate?.recipientTextViewModel(self,
                                                   didChangeRecipients: recipients, hiddenRecipients: nil)
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

    public func remove(recipient: String) {
        initialRecipients = initialRecipients.filter({$0.address != recipient})
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
        removeBadgeTextAttachments()
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

    public func removeRecipientAttachment(attachment: TextAttachment) {
        recipientAttachments = recipientAttachments.filter({$0 != attachment})
    }

    /// Remove all recipients that matches the address of the givven TextAttachment.
    /// If the user wants to remove certain recipient but enter his address more than once, all occurence must be removed. .
    public func removeAllRecipientAttachmentOfTheSameRecipient(attachment: TextAttachment) {
        recipientAttachments = recipientAttachments.filter({$0.recipient.address != attachment.recipient.address})
    }

    @discardableResult private func tryGenerateValidAddressAndUpdateStatus(range: NSRange, of text: NSAttributedString) -> Bool {
        return parseAndHandleValidEmailAddresses(inRange: range, of: text)
    }

    private func containsNothingButAttachments(text : NSAttributedString) -> Bool {
        return text.plainTextRemoved().length == text.length ||
            text.plainTextRemoved().string.trimObjectReplacementCharacters().isEmpty
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
            identityGenerated = true
            // The resultDelegate is called as a side effect in the setter of `recipientAttachments` and may depend on the isDirty state.
            // Thus we must update the isDirty state before adding the attachment
            isDirty = !identityGenerated && !containsNothingButAttachments(text: text)

            var (newText, attachment) = text.imageInserted(withAddressOf: identity,
                                                           in: range,
                                                           maxWidth: maxTextattachmentWidth)

            recipientAttachments.append(attachment)
            newText = newText.plainTextRemoved()
            newText = newText.baselineOffsetRemoved()
            newText = newText.setLineSpace(8)

            attributedText = newText

            if informDelegate {
                delegate?.textChanged(newText: newText)
            }
        } else {
            isDirty = !identityGenerated && !containsNothingButAttachments(text: text)
        }

        return identityGenerated
    }

    public func addBadge(inRange range: NSRange, of text: NSAttributedString, informDelegate: Bool = true, number: Int) {
        let identity = Identity(address: "+\(number)")
        identity.session.commit()

        var (newText, attachment) = text.imageInserted(withAddressOf: identity,
                                                       in: range,
                                                       maxWidth: maxTextattachmentWidth)
        attachment.isBadge = true
        newText = newText.plainTextRemoved()
        newText = newText.baselineOffsetRemoved()
        newText = newText.setLineSpace(8)

        attributedText = newText

        if informDelegate {
            delegate?.textChanged(newText: newText)
        }
        identity.delete()
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

// MARK: - Expand and collapse recipeints

extension RecipientTextViewModel {

    func removeBadgeTextAttachments() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard let del = me.delegate else {
                Log.shared.errorAndCrash("Delegate not found")
                return
            }
            del.removeBadgeTextAttachments()
        }
    }

    /// Shows only the recipients that fits on one line and add a new NSTextAttachment that indicates the amount of recipients that are not shown.
    /// For example, this could be shown: "bob@pep.security  alice@pep.security  +3"
    /// If there is nothing to hide, it does nothing.
    /// The hidden recipients are NSTextAttachments removed and are stored into the hidden recipients of the ComposeViewModelState .
    public func collapseRecipients() {
        // Check for historical reasons (there was a dispatch to the main queue here).
        if !Thread.isMainThread {
            Log.shared.errorAndCrash(message: "Unexpectedly not on the main thread")
        }

        guard let recipientTextAttachments = attributedText?.recipientTextAttachments() else {
            // No attachments. Nothing to do.
            return
        }

        guard let del = delegate else {
            Log.shared.errorAndCrash("Delegate not found")
            return
        }

        guard let attr = attributedText else {
            Log.shared.logError(message: "Unexpected nil attributed text")
            return
        }

        // Separate Recipient text attachments in two groups: one to show, the other to hide.
        var toShow = [RecipientTextViewModel.TextAttachment]()
        var toHide = [RecipientTextViewModel.TextAttachment]()

        recipientTextAttachments.forEach { textAttachment in
            guard let expectedWidthOfTheNewTextAttachment = textAttachment.image?.size.width else {
                Log.shared.errorAndCrash("RecipientTextViewModel.TextAttachment without image. It should not happen.")
                return
            }

            // Sum the width of every attachment to show to calculate if there is space for one more.
            let recipientsTextAttachmentWidth = toShow.compactMap { $0.image?.size.width }.reduce(0, +)

            // Evaluate if there is space for the next attachment. Group the text attachments accordingly.
            let shouldShow = del.isThereSpaceForANewTextAttachment(recipientsTextAttachmentWidth: recipientsTextAttachmentWidth, expectedWidthOfTheNewTextAttachment: expectedWidthOfTheNewTextAttachment)

            if shouldShow {
                toShow.append(textAttachment)
            } else {
                toHide.append(textAttachment)
            }
        }

        // Hide attachments that exceed the first line.
        let newRecipients = toShow.map { $0.recipient }
        let recipientsToHide = toHide.map { $0.recipient }

        if !recipientsToHide.isEmpty {
            let range = NSRange(location: max(attr.length, 0), length: 0)
            addBadge(inRange: range, of: attr, number: recipientsToHide.count)
        }
        resultDelegate?.recipientTextViewModel(self,
                                               didChangeRecipients: newRecipients,
                                               hiddenRecipients: recipientsToHide)
        delegate?.removeRecipientsTextAttachments(recipients: toHide)
    }
}
