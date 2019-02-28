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
    @IBOutlet weak var contentText: UITextView!

    public override func updateCell(model: ComposeFieldModel, message: Message) {
        updateCell(model: model, message: message, clickHandler: nil)
    }

    func updateCell(model: ComposeFieldModel, message: Message, clickHandler: UITextViewDelegate?) {
        super.updateCell(model: model, message: message)

        let finalText = NSMutableAttributedString()
        if message.underAttack {
            let status = String.pEpRatingTranslation(pEpRating: PEPRatingUnderAttack)
            let messageString = String.localizedStringWithFormat(
                NSLocalizedString(
                    "\n%1$@\n\n%2$@\n\n%3$@\n\nAttachments are disabled.\n\n",
                    comment: "Disabled attachments for a message with status 'under attack'. " +
                    "Placeholders: Title, explanation, suggestion."),
                status.title, status.explanation, status.suggestion)
            finalText.bold(messageString)
        }

        if let text = message.longMessage?.trimmed() {
            finalText.normal(text)
        } else if let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
            finalText.normal(text)
        } else if message.pEpRating().isUnDecryptable() {
            finalText.normal(NSLocalizedString(
                "This message could not be decrypted.",
                comment: "content that is shown for undecryptable messages"))
        } else {
            // Empty body
            finalText.normal("")
        }

        contentText.tintColor = UIColor.pEpGreen
        contentText.attributedText = finalText
        contentText.dataDetectorTypes = UIDataDetectorTypes.link
        contentText.delegate = clickHandler
    }
}
