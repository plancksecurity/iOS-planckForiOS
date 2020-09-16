//
//  BodyCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

protocol BodyCellViewModelResultDelegate: class {

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel)
    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel)

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           inlinedAttachmentsChanged inlinedAttachments: [Attachment])

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           bodyAttributedString: NSAttributedString)
}

protocol BodyCellViewModelDelegate: class {
    func insert(text: NSAttributedString)
}

class BodyCellViewModel: CellViewModel {
    var maxTextattachmentWidth: CGFloat = 100.0 // arbitrary non-null value
    public weak var resultDelegate: BodyCellViewModelResultDelegate?
    public weak var delegate: BodyCellViewModelDelegate?
    private var plaintext = ""
    private var attributedText: NSAttributedString?
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
         inlinedAttachments: [Attachment]? = nil) {
        self.resultDelegate = resultDelegate
        self.plaintext = initialPlaintext ?? ""
        self.attributedText = initialAttributedText
        if let inlAtt = inlinedAttachments {
            self.inlinedAttachments = inlAtt
        }
    }

    public func inititalText() -> (text: String?, attributedText: NSAttributedString?) {
        if plaintext.isEmpty {
            // commented out until IOS-1124 is done.
//            plaintext.append(.pepSignature)
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

    public let contextMenuItemTitleAttachMedia =
        NSLocalizedString("Attach media", comment: "Attach photo/video (message text context menu)")

    public let contextMenuItemTitleAttachFile =
        NSLocalizedString("Attach file",   comment: "Insert document in message text context menu")

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
        guard let image = attachment.image else {
            Log.shared.errorAndCrash("No image")
            return
        }
        attachment.session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            attachment.contentDisposition = .inline
            // Workaround: If the image has a higher resolution than that, UITextView has serious
            // performance issues (delay typing).
            guard let scaledImage = image.resized(newWidth: me.maxTextattachmentWidth / 2,
                                                  useAlpha: false)
                else {
                    Log.shared.errorAndCrash("Error resizing")
                    return
            }
            let textAttachment = TextAttachment()
            textAttachment.image = scaledImage
            textAttachment.attachment = attachment
            let margin: CGFloat = 10.0
            textAttachment.bounds = CGRect.rect(withWidth: me.maxTextattachmentWidth - margin,
                                                ratioOf: scaledImage.size)
            let imageString = NSAttributedString(attachment: textAttachment)

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
    private func createHtmlVersionAndInformDelegate(newAttributedText attrText: NSAttributedString) { //!!!: ADAM: (I assume) you made this dead code
        resultDelegate?.bodyCellViewModel(self, bodyAttributedString: attrText)
    }
}
