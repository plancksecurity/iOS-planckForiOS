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
        // The frame needed to place all attachment images
        let theFrame = CGRect(origin: CGPoint.zero,
                              size: CGSize(width: guessCellWidth(), height: 0.0))
        let view = ImageView(frame: theFrame)
        view.attachedViews = theBuildOp.attachmentViews
        view.frame = theFrame
        view.layoutIfNeeded()

        resultView = view
        delegate?.didCreate(attachmentsView: view, message: theBuildOp.message)
    }

    func updateQuickMetaData(message: Message) {
        operationQueue.cancelAllOperations()
        resultView = nil

        let theBuildOp = AttachmentsViewOperation(mimeTypes: mimeTypes, message: message,
                                                  cellWidth: cellWidth)
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
