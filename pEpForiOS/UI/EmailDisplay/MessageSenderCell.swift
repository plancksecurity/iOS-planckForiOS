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
        
        let attributed = NSMutableAttributedString(
            string: NSLocalizedString("To:", comment: "Compose field title"))
        let attributes = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 15.0),
            NSForegroundColorAttributeName: UIColor.lightGray
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
