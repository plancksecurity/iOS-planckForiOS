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

    public override func updateCell(model: ComposeFieldModel, message: Message,
                                    indexPath: IndexPath) {
        super.updateCell(model: model, message: message, indexPath: indexPath)

        contentLabel.text = ""
        if message.underAttack {
            let status = String.pEpRatingTranslation(pEpRating: PEP_rating_under_attack)
            contentLabel.text?.append(status.title)
            contentLabel.text?.append(status.explanation)
            contentLabel.text?.append(status.suggestion)
            contentLabel.text?.append("\n")
        }

        if let longmessage = message.longMessage?.trimmedWhiteSpace() {
            contentLabel.text?.append(longmessage)
        } else {
            if let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
                contentLabel.text?.append(text)
            }
        }
    }
}
