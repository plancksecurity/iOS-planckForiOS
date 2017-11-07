//
//  EmailListViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel
import SwipeCellKit

class EmailListViewCell: SwipeTableViewCell {
    static let storyboardId = "EmailListViewCell"
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

    func setPepRatingImage(image: UIImage?) {
        guard image != nil else {
            return
        }
        self.ratingImage.image = image
        self.ratingImage.isHidden = false
    }

    func setContactImage(image: UIImage?) {
        guard image != nil else {
            return
        }
        self.contactImageView.image = image
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contactImageView.layer.cornerRadius = round(contactImageView.bounds.size.width / 2)
        self.contactImageView.layer.masksToBounds = true
        resetToDefault()
    }

    override func prepareForReuse() {
        resetToDefault()
    }

    private func resetToDefault() {
        senderLabel.text = nil
        subjectLabel.text = nil
        summaryLabel.text = nil
        dateLabel.text = nil
        unsetFlagged()
        unsetSeen()
        ratingImage.isHidden = true
        hasAttachment = false
        contactImageView.image = EmailListViewCell.emptyContactImage
    }

    private func setFlagged() {
        if EmailListViewCell.flaggedImage == nil {
            EmailListViewCell.flaggedImage =
                FlagImages.create(imageSize: flaggedImageView.frame.size).flaggedImage
        }
        guard let saveImg = EmailListViewCell.flaggedImage else {
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
            setupLabels(font: font)
        }
    }

    private func unsetSeen() {
        if let font = senderLabel.font {
            let font = UIFont.boldSystemFont(ofSize: font.pointSize)
            setupLabels(font: font)
        }
    }

    func setupLabels(font: UIFont) {
        senderLabel.font = font
        subjectLabel.font = font
        summaryLabel.font = font
        dateLabel.font = font
    }
}
