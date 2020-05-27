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
        
        let font = UIFont.pepFont(style: .footnote, weight: .semibold)
        titleLabel?.font = font

        let attributes = [NSAttributedString.Key.font: font,
                          NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        var temp: [String] = []
        message.allRecipients.forEach { (recepient) in
            let recepient = recepient.address
            temp.append(recepient)
        }
        let toDestinataries = NSLocalizedString("To:", comment: "Compose field title") + temp.joined(separator: ", ")
        valueLabel?.attributedText = NSAttributedString(string: toDestinataries, attributes: attributes as [NSAttributedString.Key : Any])
        valueLabel?.font = UIFont.pepFont(style: .caption1, weight: .regular)
    }
}
