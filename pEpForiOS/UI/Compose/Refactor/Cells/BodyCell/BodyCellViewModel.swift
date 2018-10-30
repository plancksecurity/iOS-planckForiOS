//
//  BodyCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol BodyCellViewModelResultDelegate: class {
    func bodyCellViewModel(_ vm: BodyCellViewModel, textChanged newText: String) //IOS-1369:

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
    private var initialPlaintext = ""
    private var initialized = false
    private var initialAttributedText: NSAttributedString?
    private var inlinedAttachments = [Attachment]() {
        didSet {
            resultDelegate?.bodyCellViewModel(self, inlinedAttachmentsChanged: inlinedAttachments)
        }
    }

    init(resultDelegate: BodyCellViewModelResultDelegate,
         initialPlaintext: String? = nil,
         initialAttributedText: NSAttributedString? = nil,
         inlinedAttachments: [Attachment]?) {
        self.resultDelegate = resultDelegate
        self.initialPlaintext = initialPlaintext ?? ""
        self.initialAttributedText = initialAttributedText
        initialized = true
    }

    func defaultBodyText() -> String {
        return .pepSignature
    }

    func takeOverInitialData() -> Bool {
        return !initialized
    }

    func inititalText() -> (text: String?, attributedText: NSAttributedString?) {
        assureCorrectTextAtatchmentImageWidth()
        return (initialPlaintext, initialAttributedText)
    }

    //IOS-1369: obsolete?
    //    func handleDidBeginEditing() { }

    //IOS-1369: obsolete?
    //    func handleDidEndEditing() { }

    public func handleTextChange(newText: String, newAttributedText attrText: NSAttributedString) {
        createHtmlVersionAndInformDelegate(newText: newText, newAttributedText: attrText)
        resultDelegate?.bodyCellViewModel(self, textChanged: newText) //IOS-1369: I still think we AGNI. Double check.
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
        resultDelegate?.bodyCellViewModelUserWantsToAddMedia(self)
    }

    public func handleUserClickedSelectDocument() {
        resultDelegate?.bodyCellViewModelUserWantsToAddDocument(self)
    }
}

// MARK: - Attachments

extension BodyCellViewModel {
    //    extension MessageBodyCell { //IOS-1369: cleanup
    public func inline(attachment: Attachment) {
        guard let image = attachment.image else {
            Log.shared.errorAndCrash(component: #function, errorString: "No image")
            return
        }
        attachment.contentDisposition = .inline
        // Workaround: If the image has a higher resolution than that, UITextView has serious
        // performance issues (delay typing). I suspect we are causing them elswhere though.
        // IOS-1369: double check the performance issues persist. rm if they do not.
        guard let scaledImage = image.resized(newWidth: maxTextattachmentWidth / 2, useAlpha: false)
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Error resizing")
                return
        }
        let textAttachment = TextAttachment()
        textAttachment.image = scaledImage
        textAttachment.attachment = attachment
        textAttachment.bounds = CGRect.rect(withWidth: maxTextattachmentWidth,
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

    private func assureCorrectTextAtatchmentImageWidth() {
        guard let attributedText = initialAttributedText else {
            // Empty body. That's perfictly fine.
            return
        }
        for textAttachment in attributedText.textAttachments() {
            guard let image = textAttachment.image else {
                Log.shared.errorAndCrash(component: #function, errorString: "No image?")
                return
            }
            if image.size.width > maxTextattachmentWidth {
                textAttachment.image = image.resized(newWidth: maxTextattachmentWidth)
            }
        }
    }
}

// MARK: - HTML

extension BodyCellViewModel {

    private func createHtmlVersionAndInformDelegate(
        newText: String,
        newAttributedText attrText: NSAttributedString) {

        let (markdownText, _) = attrText.convertToMarkDown()
        let plaintext = markdownText
        let html = markdownText.markdownToHtml()
        resultDelegate?.bodyCellViewModel(self, bodyChangedToPlaintext: plaintext,
                                          html: html ?? "")
    }
}
