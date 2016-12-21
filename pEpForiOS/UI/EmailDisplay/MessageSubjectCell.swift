//
//  MessageSubjectCell.swift
//
//  Created by Yves Landert on 21.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

open class MessageSubjectCell: MessageCell {
    
    let dateFormatter = UIHelper.dateFormatterEmailDetails()
    
    public override func updateCell(_ model: ComposeFieldModel, _ message: Message) {
        fieldModel = model
        titleLabel?.text = message.shortMessage
        
        if let receivedDate = message.received {
            UIHelper.putString(dateFormatter.string(from: receivedDate as Date), toLabel: valueLabel)
        } else {
            UIHelper.putString(nil, toLabel: valueLabel)
        }
    }
}
