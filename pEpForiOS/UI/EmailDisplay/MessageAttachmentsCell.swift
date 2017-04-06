//
//  MessageAttachmentsCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class MessageAttachmentsCell: MessageCell, AttachmentsViewHelperDelegate {
    @IBOutlet weak var attachmentsImageView: ImageView!
    var attachmentsViewHelper = AttachmentsViewHelper()

    public override func updateCell(model: ComposeFieldModel, message: Message,
                                    indexPath: IndexPath) {
        super.updateCell(model: model, message: message, indexPath: indexPath)
        titleLabel?.text = "Attachments"
        attachmentsViewHelper.attachmentsImageView = attachmentsImageView
        attachmentsViewHelper.delegate = self
        attachmentsViewHelper.message = message
    }
}

// MARK: - AttachmentsViewHelperDelegate

extension MessageAttachmentsCell {
    func didCreate(attachmentsView: UIView?, message: Message) {
        (delegate as? MessageContentCellDelegate)?.didUpdate(cell: self, height: 0)
    }
}
