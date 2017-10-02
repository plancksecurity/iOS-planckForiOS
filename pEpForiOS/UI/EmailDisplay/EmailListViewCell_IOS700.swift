//
//  EmailListViewCell_IOS700.swift
//  pEp
//
//  Created by Andreas Buff on 29.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

class EmailListViewCell_IOS700: UITableViewCell {
    static var flaggedImage: UIImage? = nil
    static var emptyContactImage = UIImage.init(named: "empty-avatar")

    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    /**
     Used for \Flagged, contrary to the name.
     */
    @IBOutlet weak var flaggedImageView: UIImageView!

    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var attachmentIcon: UIImageView!
    @IBOutlet weak var contactImageView: UIImageView!

    var isFlagged:Bool = false {
        didSet {
            if isFlagged {
                setFlagged()
            } else {
                unsetFlagged()
            }
        }
    }

    var isSeen:Bool = false {
        didSet {
            if isSeen {
                setSeen()
            } else {
                unsetSeen()
            }
        }
    }

    var hasAttachment:Bool = false {
        didSet {
            if hasAttachment {
                attachmentIcon.isHidden = false
            } else {
                attachmentIcon.isHidden = true
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = UITableViewCellSelectionStyle.none

        self.contactImageView.layer.cornerRadius = round(contactImageView.bounds.size.width / 2)
        self.contactImageView.layer.masksToBounds = true
        self.contactImageView.image = EmailListViewCell_IOS700.emptyContactImage
    }

    override func prepareForReuse() {
        senderLabel.text = nil
        subjectLabel.text = nil
        summaryLabel.text = nil
        dateLabel.text = nil
        unsetFlagged()
        unsetSeen()
        ratingImage.isHidden = true
        hasAttachment = false
        contactImageView.image = EmailListViewCell_IOS700.emptyContactImage
    }

    private func setFlagged() {
        if EmailListViewCell_IOS700.flaggedImage == nil {
            EmailListViewCell_IOS700.flaggedImage =
                FlagImages.create(imageSize: flaggedImageView.frame.size).flaggedImage
        }
        guard let saveImg = EmailListViewCell_IOS700.flaggedImage else {
            return
        }
        self.flaggedImageView.isHidden = false
        self.flaggedImageView.image = saveImg
    }

    private func unsetFlagged() {
        self.flaggedImageView.isHidden = true
        self.flaggedImageView.image = nil
    }

    private func setSeen() {
        if let font = senderLabel.font {
            let font = UIFont.systemFont(ofSize: font.pointSize)
            setLabels(font: font)
        }
    }

    private func unsetSeen() {
        if let font = senderLabel.font {
            let font = UIFont.boldSystemFont(ofSize: font.pointSize)
            setLabels(font: font)
        }
    }

    func setLabels(font: UIFont) { //BUFF: rename
        senderLabel.font = font
        subjectLabel.font = font
        summaryLabel.font = font
        dateLabel.font = font
    }

    //BUFF: to VC
    //    func updatePepRating(message: Message) {
    //        let color = PEPUtil.pEpColor(pEpRating: message.pEpRating(session: theSession))
    //        ratingImage.image = color.statusIcon()
    //        ratingImage.backgroundColor = nil
    //    }

    //            identityForImage = message.from
    //            if let ident = identityForImage, let imgProvider = config?.imageProvider {
    //                imgProvider.image(forIdentity: ident) { img, ident in
    //                    if ident == self.identityForImage {
    //                        self.contactImageView.image = img
    //                    }
    //                }
    //            }

    //    // Seperation of concerns is broken here. An UI element must not now anything about model/bussness logic,
    //    // thus is must not know about a PEPSession
    //    func configureCell(config: EmailListConfig?, indexPath: IndexPath, session: PEPSession) -> Message? {
            //        self.session = theSession
            //        self.config = config
            //
            //        if let message = messageAt(indexPath: indexPath, config: config) {
            //            UIHelper.putString(message.from?.userNameOrAddress, toLabel: self.senderLabel)
            //            UIHelper.putString(message.shortMessage, toLabel: self.subjectLabel)
            //
    //            // Snippet
    //            if let text = message.longMessage {
    //                let theText = text.replaceNewLinesWith(" ").trimmedWhiteSpace()
    //                UIHelper.putString(UIHelper.cleanHtml(theText), toLabel: self.summaryLabel)
    //            } else if let html = message.longMessageFormatted {
    //                var text = html.extractTextFromHTML()
    //                text = text?.replaceNewLinesWith(" ").trimmedWhiteSpace()
    //                UIHelper.putString(text, toLabel: self.summaryLabel)
    //            } else {
    //                UIHelper.putString(nil, toLabel: self.summaryLabel)
    //            }
    //
            //            if let originationDate = message.sent {
            //                UIHelper.putString(originationDate.smartString(), toLabel: self.dateLabel)
            //            } else {
            //                UIHelper.putString(nil, toLabel: self.dateLabel)
            //            }
            //
            //            attachmentIcon.isHidden = message.viewableAttachments().count > 0 ? false : true
            //            updateFlags(message: message)
            //            updatePepRating(message: message)
            //
            //            contactImageView.image = UIImage.init(named: "empty-avatar")
            //            identityForImage = message.from
            //            if let ident = identityForImage, let imgProvider = config?.imageProvider {
            //                imgProvider.image(forIdentity: ident) { img, ident in
            //                    if ident == self.identityForImage {
            //                        self.contactImageView.image = img
            //                    }
            //                }
            //            }
            //
            //            return message
            //        }
            //        return nil
            //    }

            //    /**
            //     The message at the given position.
            //     */
            //    func haveSeen(message: Message) -> Bool {
            //        return message.imapFlags?.seen ?? false
            //    }
            //
            //    func isFlagged(message: Message) -> Bool {
            //        return message.imapFlags?.flagged ?? false
            //    }
            //
            //    func messageAt(indexPath: IndexPath, config: EmailListConfig?) -> Message? {
            //        if let fol = config?.folder {
            //            return fol.messageAt(index: indexPath.row)
            //        }
            //        return nil
            //    }
}
