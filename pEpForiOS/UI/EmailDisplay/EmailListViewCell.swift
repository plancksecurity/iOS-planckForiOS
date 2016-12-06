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
    @IBOutlet weak var isImportantImage: UIImageView!
    
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

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.none

        // generated an circle image
        isImportantImage.layer.cornerRadius = isImportantImage.frame.size.width / 2
        isImportantImage.clipsToBounds = true

        isImportantImage.isHidden = false
        isImportantImage.backgroundColor = UIColor.blue
    }
    
    func configureCell(indexPath: IndexPath, config: EmailListConfig) {
        
        if !determinedCellBackgroundColor {
            defaultCellBackgroundColor = self.backgroundColor
            determinedCellBackgroundColor = true
        }
        
        if let email = messageAt(indexPath: indexPath, config: config) {
            if let pEpRating = PEPUtil.pEpRatingFromInt(email.pEpRatingInt) {
                let privacyColor = PEPUtil.pEpColor(pEpRating: pEpRating)
                if let uiColor = UIHelper.textBackgroundUIColorFromPrivacyColor(privacyColor) {
                    self.backgroundColor = uiColor
                } else {
                    if determinedCellBackgroundColor {
                        self.backgroundColor = defaultCellBackgroundColor
                    }
                }
            }
            UIHelper.putString(email.from?.displayString, toLabel: self.senderLabel)
            UIHelper.putString(email.shortMessage, toLabel: self.subjectLabel)
            
            // Snippet
            if let text = email.longMessage {
                let theText = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
                UIHelper.putString(UIHelper.cleanHtml(theText), toLabel: self.summaryLabel)
            } else if let html = email.longMessageFormatted {
                var text = html.extractTextFromHTML()
                text = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
                UIHelper.putString(text, toLabel: self.summaryLabel)
            } else {
                UIHelper.putString(nil, toLabel: self.summaryLabel)
            }
            
            if let receivedDate = email.received {
                UIHelper.putString(dateFormatter.string(from: receivedDate as Date),
                                   toLabel: self.dateLabel)
            } else {
                UIHelper.putString(nil, toLabel: self.dateLabel)
            }
            
            if (isImportant(message: email) && isRead(message: email)) {
                self.isImportantImage.isHidden = false
                self.isImportantImage.backgroundColor = UIColor.orange
            }
            else if (isImportant(message: email) && !isRead(message: email)) {
                self.isImportantImage.isHidden = false
                self.isImportantImage.backgroundColor = UIColor.blue
                self.isImportantImage.layer.borderWidth = 2
                self.isImportantImage.layer.borderColor = UIColor.orange.cgColor
            } else if (!isImportant(message: email) && isRead(message: email)) {
                self.isImportantImage.isHidden = true
            } else if (!isImportant(message: email) && !isRead(message: email)) {
                self.isImportantImage.isHidden = false
                self.isImportantImage.backgroundColor = UIColor.blue
            }
        }
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
    
    func messageAt(indexPath: IndexPath, config: EmailListConfig) -> Message? {
        if let fol = config.folder {
            return fol.messageByIndex(indexPath.row)
        }
        return nil
    }
}
