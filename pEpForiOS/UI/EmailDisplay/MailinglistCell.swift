//
//  MailinglistCell.swift
//
//  Created by Yves Landert on 21.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit

import MessageModel

open class MailinglistCell: MessageCell {
    public override func updateCell(model: ComposeFieldModel, message: Message) {
        super.updateCell(model: model, message: message)
        height = 0
    }
}
