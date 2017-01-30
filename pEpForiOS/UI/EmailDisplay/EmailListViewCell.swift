//
//  EmailListViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit
import MessageModel

class EmailListViewCell: UITableViewCell {
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var isReadMessageImage: UIImageView!
    @IBOutlet weak var disclousureImage: UIImageView!
    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var attachmentIcon: UIImageView!
    
    /**
     Indicates whether `defaultCellBackgroundColor` has been determined or not.
     */
    var determinedCellBackgroundColor: Bool = false
    
    /**
     The default background color for an email cell, as determined the first time a cell is
     created.
     */
    var defaultCellBackgroundColor: UIColor?

    let dateFormatter = UIHelper.dateFormatterEmailList()

    var indexPath: IndexPath?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.none

        // generated an circle image
        isReadMessageImage.layer.cornerRadius = isReadMessageImage.frame.size.width / 2
        isReadMessageImage.clipsToBounds = true

        isReadMessageImage.isHidden = false
        isReadMessageImage.backgroundColor = .pEpBlue
    }

    func updateFlags(message: Message) {
        // TODO
    }
    
    func configureCell(indexPath: IndexPath, config: EmailListConfig?) -> MessageID? {
        self.indexPath = indexPath

        if !determinedCellBackgroundColor {
            defaultCellBackgroundColor = self.backgroundColor
            determinedCellBackgroundColor = true
        }
        
        if let message = messageAt(indexPath: indexPath, config: config) {
            if let pEpRating = PEPUtil.pEpRatingFromInt(message.pEpRatingInt) {
                let privacyColor = PEPUtil.pEpColor(pEpRating: pEpRating)
                if let uiColor = UIHelper.textBackgroundUIColorFromPrivacyColor(privacyColor) {
                    self.backgroundColor = uiColor
                } else {
                    if determinedCellBackgroundColor {
                        self.backgroundColor = defaultCellBackgroundColor
                    }
                }
            }
            UIHelper.putString(message.from?.userName, toLabel: self.senderLabel)
            UIHelper.putString(message.shortMessage, toLabel: self.subjectLabel)
            
            // Snippet
            if let text = message.longMessage {
                let theText = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
                UIHelper.putString(UIHelper.cleanHtml(theText), toLabel: self.summaryLabel)
            } else if let html = message.longMessageFormatted {
                var text = html.extractTextFromHTML()
                text = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
                UIHelper.putString(text, toLabel: self.summaryLabel)
            } else {
                UIHelper.putString(nil, toLabel: self.summaryLabel)
            }
            
            if let originationDate = message.received {
                UIHelper.putString(dateFormatter.string(from: originationDate as Date),
                                   toLabel: self.dateLabel)
            } else {
                UIHelper.putString(nil, toLabel: self.dateLabel)
            }
            if (isRead(message: message)) {
                self.isReadMessageImage.isHidden = true
            }
            else if (!isRead(message: message)) {
                self.isReadMessageImage.isHidden = false
                self.isReadMessageImage.backgroundColor = .pEpBlue
            }
            
            attachmentIcon.isHidden = message.attachments.count > 0 ? false : true

            updateFlags(message: message)

            return message.messageID
        }
        return nil
    }
    
    /**
     The message at the given position.
     */
    func isRead(message: Message)-> Bool {
        return message.imapFlags?.seen ?? false
    }
    
    func isImportant(message: Message)-> Bool {
        return message.imapFlags?.flagged ?? false
    }
    
    func messageAt(indexPath: IndexPath, config: EmailListConfig?) -> Message? {
        if let fol = config?.folder {
            return fol.messageAt(index: indexPath.row)
        }
        return nil
    }
}
