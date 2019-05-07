//
//  AttachmentsViewHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import MessageModel

protocol AttachmentsViewHelperDelegate: class {
    /**
     You can rely on this method always be called on the UI thread.
     */
    func didCreate(attachmentsView: UIView?, message: Message)
}

class AttachmentsViewHelper {
    weak var delegate: AttachmentsViewHelperDelegate?
    var attachmentsImageView: AttachmentsView?

    var message: Message? {
        didSet {
            if let m = message {
                updateQuickMetaData(message: m)
            }
        }
    }

    let mimeTypes = MimeTypeUtils()
    var buildOp: AttachmentsViewOperation?
    let operationQueue = OperationQueue()

    init(delegate: AttachmentsViewHelperDelegate?) {
        self.delegate = delegate
    }

    convenience init() {
        self.init(delegate: nil)
    }

    func attachmentInfo(attachment: Attachment) -> AttachmentSummaryView.AttachmentInfo {
        let (name, ext) =
            attachment.fileName?.splitFileExtension() ?? (Constants.defaultFileName, nil)
        return AttachmentSummaryView.AttachmentInfo(
            filename: name.extractFileNameOrCid(),
            theExtension: ext ?? mimeTypes?.getFileExtension(attachment.mimeType))
    }

    func opFinished(theBuildOp: AttachmentsViewOperation) {
        if let imageView = attachmentsImageView {
            let viewContainers = theBuildOp.attachmentContainers.map {
                (c: AttachmentsViewOperation.AttachmentContainer) -> (AttachmentViewContainer) in
                switch c {
                case .imageAttachment(let attachment, let image):
                    return AttachmentViewContainer(view: UIImageView(image: image),
                                                   attachment: attachment)
                case .docAttachment(let attachment):
                    let dic = UIDocumentInteractionController()
                    dic.name = attachment.fileName

                    let theAttachmentInfo = attachmentInfo(attachment: attachment)

                    let theView = AttachmentSummaryView(
                        attachmentInfo: theAttachmentInfo,
                        iconImage: dic.icons.first)
                    return AttachmentViewContainer(view: theView, attachment: attachment)
                }
            }
            imageView.attachmentViewContainers = viewContainers
            delegate?.didCreate(attachmentsView: imageView, message: theBuildOp.message)
        }
    }

    func updateQuickMetaData(message: Message) {
        operationQueue.cancelAllOperations()

        let theBuildOp = AttachmentsViewOperation(mimeTypes: mimeTypes, message: message)
        buildOp = theBuildOp
        theBuildOp.completionBlock = { [weak self] in
            theBuildOp.completionBlock = nil
            if theBuildOp.message == message {
                if let mySelf = self {
                    GCD.onMain {
                        mySelf.opFinished(theBuildOp: theBuildOp)
                    }
                }
            }
        }
        operationQueue.addOperation(theBuildOp)
    }
}
