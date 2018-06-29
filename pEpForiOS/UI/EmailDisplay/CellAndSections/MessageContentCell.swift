//
//  MessageContentCell.swift
//
//  Created by Yves Landert on 20.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import MessageModel

open class MessageContentCell: MessageCell {
        @IBOutlet weak var contentLabel: UILabel!

    public override func updateCell(model: ComposeFieldModel, message: Message) {
        super.updateCell(model: model, message: message)

        let finalText = NSMutableAttributedString()
        if message.underAttack {
            let status = String.pEpRatingTranslation(pEpRating: PEP_rating_under_attack)
            let messageString = String(
                format: NSLocalizedString(
                    "\n%@\n\n%@\n\n%@\n\nAttachments are disabled.\n\n",
                    comment: "Disabled attachments for a message with status 'under attack'. Placeholders: title, explanation, suggestion."),
                status.title, status.explanation, status.suggestion)
            finalText.bold(messageString)
            //if there will be attachmetns show warning
        }

        if let text = message.longMessage?.trimmedWhiteSpace() {
            finalText.normal(text)
        } else if let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
            finalText.normal(text)
        } else {
            // Empty body
            finalText.normal("")
        }
        contentLabel.attributedText = finalText
    }
}
