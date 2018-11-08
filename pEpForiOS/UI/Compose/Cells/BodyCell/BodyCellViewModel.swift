//
//  BodyCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol BodyCellViewModelResultDelegate: class {
    func bodyCellViewModelTextChanged(_ vm: BodyCellViewModel)

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel)
    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel)

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           inlinedAttachmentsChanged inlinedAttachments: [Attachment])

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           bodyChangedToPlaintext plain: String,
                           html: String)
}

protocol BodyCellViewModelDelegate: class {
    func insert(text: NSAttributedString)
}

class BodyCellViewModel: CellViewModel {
    var maxTextattachmentWidth: CGFloat = 0.0
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

    init(resultDelegate: BodyCellViewModelResultDelegate,
         initialPlaintext: String? = nil,
         initialAttributedText: NSAttributedString? = nil,
         inlinedAttachments: [Attachment]?) {
        self.resultDelegate = resultDelegate
        self.plaintext = initialPlaintext ?? ""
        self.attributedText = initialAttributedText
    }

    public func inititalText() -> (text: String?, attributedText: NSAttributedString?) {
        if plaintext.isEmpty {
            plaintext.append(.pepSignature)
        }
        attributedText?.assureMaxTextAttachmentImageWidth(maxTextattachmentWidth)
        return (plaintext, attributedText)
    }

    public func handleTextChange(newText: String, newAttributedText attrText: NSAttributedString) {
        plaintext = newText
        attributedText = attrText
        createHtmlVersionAndInformDelegate(newAttributedText: attrText)
        resultDelegate?.bodyCellViewModelTextChanged(self)
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
            Log.shared.errorAndCrash(component: #function, errorString: "No image")
            return
        }
        attachment.contentDisposition = .inline
        // Workaround: If the image has a higher resolution than that, UITextView has serious
        // performance issues (delay typing).
        guard let scaledImage = image.resized(newWidth: maxTextattachmentWidth / 2, useAlpha: false)
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Error resizing")
                return
        }
        let textAttachment = TextAttachment()
        textAttachment.image = scaledImage
        textAttachment.attachment = attachment
        let margin: CGFloat = 10.0
        textAttachment.bounds = CGRect.rect(withWidth: maxTextattachmentWidth - margin,
                                            ratioOf: scaledImage.size)
        let imageString = NSAttributedString(attachment: textAttachment)

        delegate?.insert(text: imageString)
        inlinedAttachments.append(attachment)
    }

    private func removeInlinedAttachments(_ removees: [Attachment]) {
        if removees.count > 0 {
            inlinedAttachments = inlinedAttachments.filter { !removees.contains($0) }
        }
    }
}

// MARK: - HTML

extension BodyCellViewModel {

    private func createHtmlVersionAndInformDelegate(newAttributedText attrText: NSAttributedString) {

        let (markdownText, _) = attrText.convertToMarkDown()
        let plaintext = markdownText
        let html = markdownText.markdownToHtml()
        resultDelegate?.bodyCellViewModel(self, bodyChangedToPlaintext: plaintext,
                                          html: html ?? "")
    }
}
