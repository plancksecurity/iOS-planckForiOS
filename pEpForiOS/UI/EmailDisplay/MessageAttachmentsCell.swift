//
//  MessageAttachmentsCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class MessageAttachmentsCell: MessageCell, AttachmentsViewHelperDelegate, AttachmentsViewDelegate {
    @IBOutlet weak var attachmentsImageView: AttachmentsView!

    var attachmentsViewHelper = AttachmentsViewHelper()
    var lastMessage: Message?

    override func awakeFromNib() {
        attachmentsViewHelper.attachmentsImageView = attachmentsImageView
        attachmentsViewHelper.delegate = self
        attachmentsImageView.delegate = self
        selectionStyle = .none
    }

    public override func updateCell(model: ComposeFieldModel, message: Message,
                                    indexPath: IndexPath) {
        super.updateCell(model: model, message: message, indexPath: indexPath)

        if let m = lastMessage, m == message {
            // Avoid processing the same message over and over again, unless
            // the attachment count changes, which is considered by `==`.
            return
        }
        attachmentsViewHelper.message = message
        lastMessage = message
    }
}

// MARK: - AttachmentsViewDelegate

extension MessageAttachmentsCell {
    func didTap(attachment: Attachment, location: CGPoint, inView: UIView?) {
        (delegate as? MessageAttachmentDelegate)?.didTap(cell: self, attachment: attachment,
                                                         location: location, inView: inView)
    }
}

// MARK: - AttachmentsViewHelperDelegate

extension MessageAttachmentsCell {
    func didCreate(attachmentsView: UIView?, message: Message) {
        (delegate as? MessageContentCellDelegate)?.didUpdate(cell: self, height: 0)
    }
}
