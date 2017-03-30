//
//  MessageAttachmentsCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class MessageAttachmentsCell: MessageCell {
    open override func awakeFromNib() {
        super.awakeFromNib()
    }

    public override func updateCell(model: ComposeFieldModel, message: Message,
                                    indexPath: IndexPath) {
        super.updateCell(model: model, message: message, indexPath: indexPath)
        height = 0
    }
}
