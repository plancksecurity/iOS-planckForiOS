//
//  MessageSenderCell.swift
//  MailComposer
//
//  Created by Yves Landert on 21.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

open class MessageSenderCell: MessageCell {
    
    public override func updateCell(_ model: ComposeFieldModel, _ message: Message) {
        fieldModel = model
        titleLabel?.text = message.from?.displayString
        
        let attributed = NSMutableAttributedString(string: "Message.To".localized)
        let attributes = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 15.0),
            NSForegroundColorAttributeName: UIColor.lightGray
        ]
        
        message.allRecipients.forEach { (recepient) in
            let recepient = NSAttributedString(string: recepient.address + ", ", attributes: attributes)
            attributed.append(recepient)
        }
        valueLabel?.attributedText = attributed
    }
}
