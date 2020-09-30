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

public protocol MessageContentCellDelegate: MessageCellDelegate {
    func heightChanged()
}

open class MessageContentCell: MessageCell {
    @IBOutlet weak var contentText: UITextView!

    public override func updateCell(model: ComposeFieldModel, message: Message) {
        updateCell(model: model, message: message, clickHandler: nil)
    }

    func updateCell(model: ComposeFieldModel,
                    message: Message,
                    clickHandler: UITextViewDelegate?) {
        super.updateCell(model: model, message: message)

        var isMessageUndecryptable = false
        let group = DispatchGroup()
        group.enter()
        message.pEpRating { (rating) in
            isMessageUndecryptable = rating.isUnDecryptable()
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let me = self else {
                // Valid case. The cell or view might have been dismissed already.
                // Do nothing.
                return
            }
            let finalText = NSMutableAttributedString()
            if message.underAttack {
                let status = String.pEpRatingTranslation(pEpRating: .underAttack)
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
            } else if isMessageUndecryptable {
                finalText.normal(NSLocalizedString(
                    "This message could not be decrypted.",
                    comment: "content that is shown for undecryptable messages"))
            } else {
                // Empty body
                finalText.normal("")
            }

            me.contentText.tintColor = UIColor.pEpGreen
            me.contentText.attributedText = finalText
            me.contentText.dataDetectorTypes = UIDataDetectorTypes.link
            me.contentText.delegate = clickHandler

            guard let listener = me.delegate as? MessageContentCellDelegate else {
                // No one is interested. Valid.
                return
            }
            DispatchQueue.main.async {
                listener.heightChanged()
            }
        }
    }
}
