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

    func bodyCellViewModel(_ vm: BodyCellViewModel, didInsertAttachment att: Attachment)
}

protocol BodyCellViewModelDelegate: class {
    //IOS-1369:
    func insert(text: NSAttributedString)
}

class BodyCellViewModel: CellViewModel {
    var maxTextattachmentWidth: CGFloat = 0.0
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
}

// MARK: - Attachments

extension BodyCellViewModel {
    //    extension MessageBodyCell {
    public final func inline(attachment: Attachment) {
        guard let image = attachment.image else {
            Log.shared.errorAndCrash(component: #function, errorString: "No image")
            return
        }
        // Workaround: If the image has a higher resolution than that, UITextView has serious
        // performance issues (delay typing). I suspect we are causing them elswhere though.
        // IOS-1369: doulve check the performance issues persist. rm if they do not.
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
        resultDelegate?.bodyCellViewModel(self, didInsertAttachment: attachment)
    }
}

    /*

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


    //WIP

*/
