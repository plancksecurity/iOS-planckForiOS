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
        @IBOutlet weak var contentLabel: UILabel! //IOS-836:

    public override func updateCell(model: ComposeFieldModel, message: Message) {
        super.updateCell(model: model, message: message)

        let finalText = NSMutableAttributedString()
        if message.underAttack {
            let status = String.pEpRatingTranslation(pEpRating: PEP_rating_under_attack)
            finalText.bold("\n" + status.title + "\n\n" + status.explanation + "\n\n" + status.suggestion
                + "\n\n" + NSLocalizedString("Attachments are disabled.", comment: "Disabled attachments") + "\n\n")
            //if there will be attachmetns show warning
        }

//        if let text = message.longMessage?.trimmedWhiteSpace() {
//            finalText.normal(text)
//        } else if let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
//            finalText.normal(text)
//        } else {
//            // Empty body
//            finalText.normal("")
//        }

        finalText.normal("Buff\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1\n1")

//        if let longmessage = message.longMessage?.trimmedWhiteSpace() {
//            finalText.normal(longmessage)
//        } elseif let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
//                finalText.normal(text)
//            }
//        }
        contentLabel.attributedText = finalText //IOS-836:
//        (delegate as? MessageContentCellDelegate)?.didUpdate(cell: self, height: 0)   
    }
}
