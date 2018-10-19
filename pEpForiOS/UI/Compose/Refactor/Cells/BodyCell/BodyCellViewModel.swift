//
//  BodyCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel


protocol BodyCellViewModelResultDelegate: class {
    func bodyCellViewModel(_ vm: BodyCellViewModel, textChanged newText: String)

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel)
    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel)
}

protocol BodyCellViewModelDelegate: class {
    //IOS-1369:
}

class BodyCellViewModel: CellViewModel {
    public weak var resultDelegate: BodyCellViewModelResultDelegate?
    public weak var delegate: BodyCellViewModelDelegate?
    public private(set) var isDirty = false
    //IOS-1369: attachments go here?

    init(resultDelegate: BodyCellViewModelResultDelegate,
         initialText: String? = nil,
         initialAttributedText: NSAttributedString? = nil) {
        self.resultDelegate = resultDelegate
        //IOS-1369: set initial
    }

    //IOS-1369: obsolete?
    //    func handleDidBeginEditing() { }

    //IOS-1369: obsolete?
    //    func handleDidEndEditing() { }

    public func handleTextChange(newText: String) {
        isDirty = true
        resultDelegate?.bodyCellViewModel(self, textChanged: newText)
    }

    // MARK: - Context Menu

    public let contextMenuItemTitleAttachMedia =
        NSLocalizedString("Attach media", comment: "Attach photo/video (message text context menu)")
    public let contextMenuItemTitleAttachFile =
        NSLocalizedString("Attach file",   comment: "Insert document in message text context menu")

    public func handleUserClickedSelectMedia() {
        resultDelegate?.bodyCellViewModelUserWantsToAddMedia(self)

        /*
         private func inline(image: UIImage, forMediaWithInfo info: [String: Any]) {
         guard let cell = tableView.cellForRow(at: currentCellIndexPath) as? MessageBodyCell,
         let url = info[UIImagePickerControllerReferenceURL] as? URL
         else {
         Log.shared.errorAndCrash(component: #function, errorString: "Problem!")
         return
         }

         let attachment = createAttachment(forAssetWithUrl: url, image: image)
         cell.inline(attachment: attachment)
         tableView.updateSize()
         }
         */
    }

    public func handleUserClickedSelectDocument() {
        resultDelegate?.bodyCellViewModelUserWantsToAddDocument(self)
    }

    /*
     extension MessageBodyCell {
     public final func inline(attachment: Attachment) {
     guard let image = attachment.image else {
     Log.shared.errorAndCrash(component: #function, errorString: "No image")
     return
     }
     // Workaround: If the image has a higher resolution than that, UITextView has serious
     // performance issues (delay typing). I suspect we are causing them elswhere though.
     guard let scaledImage = image.resized(newWidth: frame.size.width / 2, useAlpha: false)
     else {
     Log.shared.errorAndCrash(component: #function, errorString: "Error resizing")
     return
     }

     let textAttachment = TextAttachment()
     textAttachment.image = scaledImage
     textAttachment.attachment = attachment
     textAttachment.bounds = CGRect.rect(withWidth: textView.bounds.width,
     ratioOf: scaledImage.size)
     let imageString = NSAttributedString(attachment: textAttachment)

     let selectedRange = textView.selectedRange
     let attrText = NSMutableAttributedString(attributedString: textView.attributedText)
     attrText.replaceCharacters(in: selectedRange, with: imageString)
     textView.attributedText = attrText
     }

     public final func allInlinedAttachments() -> [Attachment] {
     let attachments = textView.attributedText.textAttachments()
     var mailAttachments = [Attachment]()
     attachments.forEach { (attachment) in
     if let attch = attachment.attachment {
     attch.contentDisposition = .inline
     mailAttachments.append(attch)
     }
     }
     return mailAttachments
     }

     public func hasInlinedAttatchments() -> Bool {
     return allInlinedAttachments().count > 0
     }
     }
     */

    //WIP


}
