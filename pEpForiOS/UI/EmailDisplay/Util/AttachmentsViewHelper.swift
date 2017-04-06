//
//  AttachmentsViewHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol AttachmentsViewHelperDelegate: class {
    func didCreate(attachmentsView: UIView?, message: Message)
}

class AttachmentsViewHelper {
    weak var delegate: AttachmentsViewHelperDelegate?
    var attachmentsImageView: ImageView?

    var cellWidth: CGFloat?

    var message: Message? {
        didSet {
            if let m = message {
                updateQuickMetaData(message: m)
            }
        }
    }
    var attachmentsCount = 0
    var hasAttachments: Bool {
        return attachmentsCount > 0
    }

    var resultView: UIView?

    let mimeTypes = MimeTypeUtil()
    var buildOp: AttachmentsViewOperation?
    let operationQueue = OperationQueue()

    init(delegate: AttachmentsViewHelperDelegate?) {
        self.delegate = delegate
    }

    convenience init() {
        self.init(delegate: nil)
    }

    func guessCellWidth() -> CGFloat {
        return cellWidth ?? UIScreen.main.bounds.width
    }

    func opFinished(theBuildOp: AttachmentsViewOperation) {
        if let imageView = attachmentsImageView {
            imageView.attachedViews = theBuildOp.attachmentViews
            delegate?.didCreate(attachmentsView: imageView, message: theBuildOp.message)
        }
    }

    func updateQuickMetaData(message: Message) {
        operationQueue.cancelAllOperations()
        resultView = nil

        let theBuildOp = AttachmentsViewOperation(mimeTypes: mimeTypes, message: message)
        buildOp = theBuildOp
        attachmentsCount = theBuildOp.attachmentsCount
        theBuildOp.completionBlock = { [weak self] in
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
