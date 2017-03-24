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

    /**
     This is not just the image for the "seen" flag, it is used for all.
     */
    @IBOutlet weak var isReadMessageImage: UIImageView!

    /** Not used */
    @IBOutlet weak var disclousureImage: UIImageView!

    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var attachmentIcon: UIImageView!
    @IBOutlet weak var contactImageView: UIImageView!

    let dateFormatter = UIHelper.dateFormatterEmailList()

    var identityForImage: Identity?
    var config: EmailListConfig?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.none

        self.contactImageView.layer.cornerRadius = contactImageView.bounds.size.width / 2
        self.contactImageView.layer.masksToBounds = true
    }

    func updateFlags(message: Message) {
        let seen = haveSeen(message: message)
        let flagged = isFlagged(message: message)

        self.isReadMessageImage.backgroundColor = nil
        if seen && !flagged {
            // show nothing
            self.isReadMessageImage.isHidden = true
            self.isReadMessageImage.image = nil
        } else {
            let fi = FlagImages.create(imageSize: isReadMessageImage.frame.size)
            self.isReadMessageImage.isHidden = false
            self.isReadMessageImage.image = fi.flagsImage(message: message)
        }
    }

    func updatePepRating(message: Message) {
        let color = PEPUtil.pEpColor(pEpRating: message.pEpRating())
        ratingImage.image = color.statusIcon()
        ratingImage.backgroundColor = nil
    }

    func configureCell(config: EmailListConfig?, indexPath: IndexPath) -> Message? {
        self.config = config

        self.config?.imageProvider.imageSize = contactImageView.bounds.size

        if let message = messageAt(indexPath: indexPath, config: config) {
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
            
            if let originationDate = message.sent {
                UIHelper.putString(dateFormatter.string(from: originationDate as Date),
                                   toLabel: self.dateLabel)
            } else {
                UIHelper.putString(nil, toLabel: self.dateLabel)
            }
            
            attachmentIcon.isHidden = message.attachments.count > 0 ? false : true
            updateFlags(message: message)
            updatePepRating(message: message)

            identityForImage = message.from
            if let ident = identityForImage, let imgProvider = config?.imageProvider {
                imgProvider.image(forIdentity: ident) { img in
                    if message.from == self.identityForImage {
                        self.contactImageView.image = img
                    }
                }
            }

            return message
        }
        return nil
    }

    override func prepareForReuse() {
        if let ident = identityForImage {
            config?.imageProvider.cancel(identity: ident)
        }
    }
    
    /**
     The message at the given position.
     */
    func haveSeen(message: Message) -> Bool {
        return message.imapFlags?.seen ?? false
    }
    
    func isFlagged(message: Message) -> Bool {
        return message.imapFlags?.flagged ?? false
    }
    
    func messageAt(indexPath: IndexPath, config: EmailListConfig?) -> Message? {
        if let fol = config?.folder {
            return fol.messageAt(index: indexPath.row)
        }
        return nil
    }
}
