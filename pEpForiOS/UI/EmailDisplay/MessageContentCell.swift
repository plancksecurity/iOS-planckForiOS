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

        let finalText = NSMutableAttributedString()
        if message.underAttack {
            let status = String.pEpRatingTranslation(pEpRating: PEP_rating_under_attack)
            finalText.bold("\n" + status.title + "\n\n" + status.explanation + "\n\n" + status.suggestion
                + "\n\n" + NSLocalizedString("Attachments are disabled.", comment: "Disabled attachments") + "\n\n")
            //if there will be attachmetns show warning
        }

        if let longmessage = message.longMessage?.trimmedWhiteSpace() {
            finalText.normal(longmessage)
        } else {
            if let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
                finalText.normal(text)
            }
        }
        contentLabel.attributedText = finalText
    }
}
