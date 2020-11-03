//
//  AttachmentsViewHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox
import MessageModel

protocol AttachmentsViewHelperDelegate: class {
    /**
     You can rely on this method always be called on the UI thread.
     */
    func didCreate(attachmentsView: UIView?)
}

final class AttachmentsViewHelper {
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
    let operationQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInitiated
        return createe
    }()
    
    init(delegate: AttachmentsViewHelperDelegate?) {
        self.delegate = delegate
    }

    convenience init() {
        self.init(delegate: nil)
    }

    func attachmentInfo(attachment: Attachment) -> AttachmentSummaryView.AttachmentInfo {
        let (name, finalExt) =
            attachment.fileName?.splitFileExtension() ?? (Attachment.defaultFileName, nil)

        return AttachmentSummaryView.AttachmentInfo(
            filename: name.extractFileNameOrCid(),
            theExtension: finalExt)
    }

    func opFinished(theBuildOp: AttachmentsViewOperation) {
        guard let imageView = attachmentsImageView else {
            return
        }

        let viewContainers =
            theBuildOp.attachmentContainers.compactMap { [weak self] (c: AttachmentsViewOperation.AttachmentContainer) -> (AttachmentViewContainer) in
                switch c {
                case .imageAttachment(let attachment, let image):
                    return AttachmentViewContainer(view: UIImageView(image: image),
                                                   attachment: attachment)
                case .docAttachment(let attachment):
                    var resultView: AttachmentSummaryView?
                    let session = Session.main
                    let safeAttachment = attachment.safeForSession(session)
                    session.performAndWait {
                        let dic = UIDocumentInteractionController()
                        dic.name = safeAttachment.fileName

                        guard let theAttachmentInfo = self?.attachmentInfo(attachment: safeAttachment) else {
                            Log.shared.errorAndCrash("No attachment info")
                            return
                        }

                        resultView = AttachmentSummaryView(attachmentInfo: theAttachmentInfo,
                                                           iconImage: dic.icons.first)
                    }
                    guard let safeView = resultView else {
                        fatalError()
                    }
                    return AttachmentViewContainer(view: safeView, attachment: attachment)
                }
        }
        imageView.attachmentViewContainers = viewContainers
        delegate?.didCreate(attachmentsView: imageView)
    }

    func updateQuickMetaData(message: Message) {
        operationQueue.cancelAllOperations()

        let theBuildOp = AttachmentsViewOperation(mimeTypes: mimeTypes, message: message)
        buildOp = theBuildOp
        theBuildOp.completionBlock = { [weak self] in
            GCD.onMain {
                self?.opFinished(theBuildOp: theBuildOp)
            }
        }
        operationQueue.addOperation(theBuildOp)
    }
}
