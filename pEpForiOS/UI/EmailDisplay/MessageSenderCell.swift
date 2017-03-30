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
    
    public override func updateCell(model: ComposeFieldModel, message: Message,
                                    indexPath: IndexPath) {
        super.updateCell(model: model, message: message, indexPath: indexPath)
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
