//
//  BodyCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
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

public protocol BodyCellViewModelResultDelegate: class {

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel)
    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel)

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           inlinedAttachmentsChanged inlinedAttachments: [Attachment])

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           bodyAttributedString: NSAttributedString)

    func bodyCellViewModelDidPaste(_ vm: BodyCellViewModel, attachment: Attachment)
}

public protocol BodyCellViewModelDelegate: class {
    func insert(text: NSAttributedString)
}

public class BodyCellViewModel: CellViewModel {
    var maxTextattachmentWidth: CGFloat = 100.0 // arbitrary non-null value
    public weak var resultDelegate: BodyCellViewModelResultDelegate?
    public weak var delegate: BodyCellViewModelDelegate?
    private var plaintext = ""
    private var attributedText: NSAttributedString?
    private var identity: Identity?
    private var session: Session

    private var inlinedAttachments = [Attachment]() {
        didSet {
            resultDelegate?.bodyCellViewModel(self, inlinedAttachmentsChanged: inlinedAttachments)
        }
    }
    private var lastKnownCursorPosition = 0
    private var restoreCursorPosition = 0
    var cursorPosition: Int {
        return restoreCursorPosition
    }

    init(resultDelegate: BodyCellViewModelResultDelegate?,
         initialPlaintext: String? = nil,
         initialAttributedText: NSAttributedString? = nil,
         inlinedAttachments: [Attachment]? = nil,
         account: Identity?,
         session: Session) {
        self.resultDelegate = resultDelegate
        self.plaintext = initialPlaintext ?? ""
        self.attributedText = initialAttributedText
        if let inlAtt = inlinedAttachments {
            self.inlinedAttachments = inlAtt
        }
        self.identity = account
        self.session = session
    }

    public func inititalText() -> (text: String?, attributedText: NSAttributedString?) {
        if plaintext.isEmpty {
            let signature = AppSettings.shared.signature(forAddress: identity?.address)
            plaintext.append("\n\n\n\n\(signature)\n")
        }
        attributedText?.assureMaxTextAttachmentImageWidth(maxTextattachmentWidth)
        return (plaintext, attributedText)
    }

    public func handleTextChange(newText: String, newAttributedText attrText: NSAttributedString) {
        plaintext = newText
        attributedText = attrText
        createHtmlVersionAndInformDelegate(newAttributedText: attrText)
    }

    /// Handle if the text should change
    ///
    /// - Parameters:
    ///   - range: The range might use the text to introduce
    ///   - text: The base text
    ///   - replaceText: The text to replace with.
    ///
    /// - Returns: True if it should replace the text in range.
    public func handleShouldChangeText(in range: NSRange,
                                       of text: NSAttributedString,
                                       with replaceText: String) -> Bool {
        if replaceText.isAttachment {
            handleAttachmentWasPaste(text: replaceText)
            return false
        }
        return shouldReplaceText(in: range, of: text, with: replaceText)
    }

    public func shouldReplaceText(in range: NSRange,
                                  of text: NSAttributedString,
                                  with replaceText: String) -> Bool {
        let attachments = text.textAttachments(range: range)
            .map { $0.attachment }
            .compactMap { $0 }
        removeInlinedAttachments(attachments)
        return true
    }

    /// Call necessary things when user finished text editing
    public func handleDidEndEditing(attributedText: NSAttributedString) {
        createHtmlVersionAndInformDelegate(newAttributedText: attributedText)
    }

    // MARK: - Context Menu

    public let contextMenuItemTitleAddPhotoOrVideo =
        NSLocalizedString("Add Photo/Video", comment: "Attach photo/video (message text context menu)")

    public let contextMenuItemTitleAddDocument =
        NSLocalizedString("Add Document",  comment: "Insert document in message text context menu")

    public func handleUserClickedSelectMedia() {
        let potentialImage = 1
        rememberCursorPosition(offset: potentialImage)
        resultDelegate?.bodyCellViewModelUserWantsToAddMedia(self)
    }

    public func handleUserClickedSelectDocument() {
        rememberCursorPosition()
        resultDelegate?.bodyCellViewModelUserWantsToAddDocument(self)
    }
}

// MARK: - Cursor Position / Selection

extension BodyCellViewModel {

    public func handleCursorPositionChange(newPosition: Int) {
        lastKnownCursorPosition = newPosition
    }
}

// MARK: - Attachments

extension BodyCellViewModel {
    public func inline(attachment: Attachment) {
        attachment.session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            attachment.contentDisposition = .inline

            let margin: CGFloat = 10.0
            let imageString = attachment.inlinedText(scaleToImageWidth: me.maxTextattachmentWidth / 2,
                                                     attachmentWidth: me.maxTextattachmentWidth - margin)

            me.delegate?.insert(text: imageString)
            me.inlinedAttachments.append(attachment)
        }
    }
}

// MARK: - Private

extension BodyCellViewModel {

    private func removeInlinedAttachments(_ removees: [Attachment]) {
        guard !removees.isEmpty else { return }
        inlinedAttachments = inlinedAttachments.filter { //Delete from message
            let attachment = $0
            var result = false
            attachment.session.performAndWait {
                result = !removees.contains(attachment)
            }
            return result
        }
        removees.first?.session.perform {
            removees.forEach { $0.delete() } //Delete from session
        }
    }

    private func handleAttachmentWasPaste(text: String) {
        guard text.isAttachment else {
            Log.shared.errorAndCrash("text is not an attachment")
            return
        }
        // Image copied from p≡p
        if let image = UIPasteboard.general.image, let data = image.jpegData(compressionQuality: 1) {
            insertImageAttachemnt(data: data, image: image, fileName: "public.jpg")
        } else {
            // Image copied from 3rd party apps
            UIPasteboard.general.items.forEach { keyValue in
                keyValue.forEach { (key, value) in
                    if let image = value as? UIImage,
                       let data = key == "public.png" ? image.pngData() : image.jpegData(compressionQuality: 1) {
                        insertImageAttachemnt(data: data, image: image, fileName: key)
                        return //Paste only one item
                    }
                }
            }
        }
    }

    private func insertImageAttachemnt(data: Data, image: UIImage, fileName: String) {
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let attachment = image.inlinedAttachment(fileName: fileName, imageData: data, in: me.session)
            DispatchQueue.main.async {
                me.resultDelegate?.bodyCellViewModelDidPaste(me, attachment: attachment)
            }
        }
    }

    private func rememberCursorPosition(offset: Int = 0) {
        restoreCursorPosition = lastKnownCursorPosition + offset
    }
}

// MARK: - HTML

extension BodyCellViewModel {
    private func createHtmlVersionAndInformDelegate(newAttributedText attrText: NSAttributedString) {
        resultDelegate?.bodyCellViewModel(self, bodyAttributedString: attrText)
    }
}
