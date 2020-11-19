//
//  MessageAttachmentsCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class MessageAttachmentsCell: MessageCell {

    @IBOutlet weak var extensionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!

    var attachmentsViewHelper = AttachmentsViewHelper()
    var lastMessage: Message?

    override func awakeFromNib() {
//        attachmentsViewHelper.attachmentsImageView = attachmentsImageView
        attachmentsViewHelper.delegate = self
//        attachmentsImageView.delegate = self
        selectionStyle = .none
    }

    public override func updateCell(model: ComposeFieldModel, message: Message) {
        super.updateCell(model: model, message: message)

        if message.underAttack {
            return
        }

        if message == lastMessage {
            // Avoid processing the same message over and over again, unless
            // the attachment count changes, which is considered by `==`.
            return
        }

        attachmentsViewHelper.message = message
        lastMessage = message

        // Work around auto-layout problems
        if !message.viewableAttachments().isEmpty {
            let cZeroHeight = contentView.heightAnchor.constraint(equalToConstant: 0)
            let cMinimumHeight = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
            cZeroHeight.isActive = false
            cMinimumHeight.isActive = true
        }
    }
}

// MARK: - AttachmentsViewDelegate

extension MessageAttachmentsCell: AttachmentsViewDelegate {
    func didTap(attachment: Attachment, location: CGPoint, inView: UIView?) {
        //TODO: change this. Cell should not know anything about Attachments.
        (delegate as? MessageAttachmentDelegate)?.didTap(cell: self, attachment: attachment,
                                                         location: location, inView: inView)
    }
}

// MARK: - AttachmentsViewHelperDelegate

extension MessageAttachmentsCell: AttachmentsViewHelperDelegate {
    
    func didCreate(attachmentsView: UIView?) {
        (delegate as? MessageContentCellDelegate)?.heightChanged()
    }
}
