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

class EmailListViewCell: SwipeTableViewCell, MessageViewModelConfigurable {
    static let storyboardId = "EmailListViewCell"
    static var flaggedImage: UIImage? = nil
    static var emptyContactImage = UIImage.init(named: "empty-avatar")

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    /** Used for \Flagged, contrary to the name. */
    @IBOutlet weak var flaggedImageView: UIImageView!
    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var attachmentIcon: UIImageView!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var messageCountLabel: UILabel?
    @IBOutlet weak var threadIndicator: UIImageView?

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

    var messageCount:Int = 0 {
        didSet {
            if messageCount > 0 {
                messageCountLabel?.text = String(messageCount)
                messageCountLabel?.isHidden = false
                threadIndicator?.isHidden = false
            } else {
                threadIndicator?.isHidden = true
                messageCountLabel?.isHidden = true
                messageCountLabel?.text = nil
            }
        }
    }


    public func configure(for viewModel: MessageViewModel) {
        addressLabel.text = viewModel.address
        subjectLabel.text = viewModel.subject
        summaryLabel.text = viewModel.bodyPeek
        isFlagged = viewModel.isFlagged
        isSeen = viewModel.isSeen
        hasAttachment = viewModel.showAttchmentIcon
        dateLabel.text = viewModel.dateText
        messageCount = viewModel.messageCount
        if viewModel.senderContactImage != nil {
            setContactImage(image: viewModel.senderContactImage)
        } else {
            viewModel.getProfilePicture {
                image in
                self.setContactImage(image: image )
            }
        }
        viewModel.getSecurityBadge {
            image in
            self.setPepRatingImage(image: image)
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
        addressLabel.text = nil
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
            flaggedImageView.isHidden = false
            flaggedImageView.image = UIImage.init(named: "icon-flagged")

    }

    private func unsetFlagged() {
        flaggedImageView.isHidden = true
        flaggedImageView.image = UIImage.init(named: "icon-unflagged")
    }

    private func setSeen() {
        if let font = addressLabel.font {
            let font = UIFont.systemFont(ofSize: font.pointSize)
            setupLabels(font: font)
        }
    }

    private func unsetSeen() {
        if let font = addressLabel.font {
            let font = UIFont.boldSystemFont(ofSize: font.pointSize)
            setupLabels(font: font)
        }
    }

    func setupLabels(font: UIFont) {
        addressLabel.font = font
        subjectLabel.font = font
        summaryLabel.font = font
        dateLabel.font = font
        messageCountLabel?.font = font
    }
}
