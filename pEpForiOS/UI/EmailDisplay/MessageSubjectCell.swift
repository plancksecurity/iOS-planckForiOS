//
//  MessageSubjectCell.swift
//
//  Created by Yves Landert on 21.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

open class MessageSubjectCell: MessageCell {
    public override func updateCell(_ model: ComposeFieldModel, _ message: Message) {
        fieldModel = model
        titleLabel?.text = message.shortMessage
        
        if let originationDate = message.sent {
            UIHelper.putString((originationDate as Date).fullString(), toLabel: valueLabel)
        } else {
            UIHelper.putString(nil, toLabel: valueLabel)
        }
    }
}
