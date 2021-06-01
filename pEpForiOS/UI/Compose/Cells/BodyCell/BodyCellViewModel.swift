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

public protocol BodyCellViewModelResultDelegate: AnyObject {

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel)
    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel)

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           inlinedAttachmentsChanged inlinedAttachments: [Attachment])

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           bodyAttributedString: NSAttributedString)
}

public protocol BodyCellViewModelDelegate: AnyObject {
    func insert(text: NSAttributedString)
}

public class BodyCellViewModel: CellViewModel {
    var maxTextattachmentWidth: CGFloat = 100.0 // arbitrary non-null value
    public weak var resultDelegate: BodyCellViewModelResultDelegate?
    public weak var delegate: BodyCellViewModelDelegate?
    private var plaintext = ""
    private var attributedText: NSAttributedString?
    private var identity: Identity?
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
         account: Identity?) {
        self.resultDelegate = resultDelegate
        self.plaintext = initialPlaintext ?? ""
        self.attributedText = initialAttributedText
        if let inlAtt = inlinedAttachments {
            self.inlinedAttachments = inlAtt
        }
        self.identity = account
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

    private func rememberCursorPosition(offset: Int = 0) {
        restoreCursorPosition = lastKnownCursorPosition + offset
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
}

// MARK: - HTML

extension BodyCellViewModel {
    private func createHtmlVersionAndInformDelegate(newAttributedText attrText: NSAttributedString) {
        resultDelegate?.bodyCellViewModel(self, bodyAttributedString: attrText)
    }
}

// MARK: - Image

extension BodyCellViewModel {

    /// Indicate if the provided text identifies an image in the body
    /// - Parameter text: The text to check
    /// - Returns: True, if it indicates it's an image. 
    public func isImage(text: String) -> Bool {
        guard text != "", text != "\n" else {
            return false
        }
        var isImage = false
        UIPasteboard.general.items.first?.forEach { (key: String, value: Any) in
            if (key == "public.url" && (value as? String) == text) || key == "public.heic" {
                isImage = true
            } else if key == "public.url" && (value as? String)?.starts(with: "cid") ?? false {
                isImage = true
            } else if key == "public.jpeg" {
                isImage = true
            } else if text.extractCid() != nil && text.extractCid() != "" {
                isImage = true
            }
        }
        return isImage
    }

    /// Retrieve the image from the clipboard.
    /// - Returns: The image if it exists, nil otherwise. 
    public func getImageFromClipboard() -> UIImage? {
        var image: UIImage?
        UIPasteboard.general.items.first?.forEach { (key: String, value: Any) in
            if key == "public.heic", let data = value as? Data {
                image = UIImage(data:data)
            } else if key == "public.jpeg" {
                image = value as? UIImage
            } else if key == "public.url",
                      let cid = (value as? NSURL)?.absoluteString?.extractCid() {
                let attachment = Attachment.by(cid: cid)
                guard let data = attachment?.data else {
                    Log.shared.errorAndCrash("Missing attachment data")
                    return
                }
                image = UIImage(data: data)
            }
        }
        return image
    }
}
