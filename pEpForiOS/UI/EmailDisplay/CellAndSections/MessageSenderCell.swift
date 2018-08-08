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
    
    public override func updateCell(model: ComposeFieldModel, message: Message) {
        super.updateCell(model: model, message: message)
        titleLabel?.text = message.from?.displayString
        
        let attributed = NSMutableAttributedString(
            string: NSLocalizedString("To: ", comment: "Compose field title"))
        let attributes = [
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15.0),
            NSAttributedStringKey.foregroundColor: UIColor.lightGray
        ]
        var temp: [String] = []
        message.allRecipients.forEach { (recepient) in
            let recepient = recepient.address
            temp.append(recepient)
        }
        attributed.append(NSAttributedString(string: temp.joined(separator: ", "), attributes: attributes))
        valueLabel?.attributedText = attributed
    }
}
