//
//  MessageSubjectCell.swift
//
//  Created by Yves Landert on 21.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel
import pEpIOSToolbox

open class MessageSubjectCell: MessageCell {
    public override func updateCell(model: ComposeFieldModel, message: Message) {
        super.updateCell(model: model, message: message)
        titleLabel?.text = message.shortMessage
        titleLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        valueLabel?.font = UIFont.pepFont(style: .footnote, weight: .semibold)
        if let originationDate = message.sent {
            UIHelper.putString((originationDate as Date).fullString(), toLabel: valueLabel)
        } else {
            UIHelper.putString(nil, toLabel: valueLabel)
        }
    }
}
