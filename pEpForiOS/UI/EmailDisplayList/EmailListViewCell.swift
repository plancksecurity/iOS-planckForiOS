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
    // MARK: Public API

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    @IBOutlet weak var flaggedImageView: UIImageView!

    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var attachmentIcon: UIImageView!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var messageCountLabel: UILabel?
    @IBOutlet weak var threadIndicator: UIImageView?

    public static let storyboardId = "EmailListViewCell"

    public var isFlagged:Bool = false {
        didSet {
            if isFlagged {
                setFlagged()
            } else {
                unsetFlagged()
            }
        }
    }

    public func configure(for viewModel: MessageViewModel) {
        self.viewModel = viewModel
        addressLabel.text = viewModel.displayedUsername
        subjectLabel.text = viewModel.subject
        viewModel.bodyPeekCompletion = { bodyPeek in
            self.summaryLabel.text = bodyPeek
        }
        isFlagged = viewModel.isFlagged
        isSeen = viewModel.isSeen
        hasAttachment = viewModel.showAttchmentIcon
        dateLabel.text = viewModel.dateText

        configureThreadIndicator(for: viewModel)
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

    public func clear() {
        viewModel.unsubscribeForUpdates()
    }

    // MARK: View overrides (life cycle etc.)

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contactImageView.applyContactImageCornerRadius()
        resetToDefault()
    }

    override func prepareForReuse() {
        resetToDefault()
    }

    override func layoutSubviews() {
        ratingImage.centerXAnchor.constraint(
            equalTo: contactImageView.rightAnchor).isActive = true
        ratingImage.centerYAnchor.constraint(
            equalTo: contactImageView.bottomAnchor).isActive = true
    }

    // MARK: Private

    private static var flaggedImage: UIImage? = nil
    private static var emptyContactImage = UIImage(named: "empty-avatar")

    private var viewModel: MessageViewModel!

    private var isSeen:Bool = false {
        didSet {
            if isSeen {
                setSeen()
            } else {
                unsetSeen()
            }
        }
    }

    private var hasAttachment:Bool = false {
        didSet {
            if hasAttachment {
                attachmentIcon.isHidden = false
            } else {
                attachmentIcon.isHidden = true
            }
        }
    }

    private var messageCount:Int = 0 {
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

    private func configureThreadIndicator(for viewModel: MessageViewModel) {
        guard let _ = messageCountLabel,
            let _ = threadIndicator else {
                messageCount = 0
                return
        }
        viewModel.messageCount { (messageCount) in
            self.messageCount = messageCount
        }

    }

    private func setPepRatingImage(image: UIImage?) {
        guard image != nil else {
            return
        }
        self.ratingImage.image = image
        self.ratingImage.isHidden = false
    }

    private func setContactImage(image: UIImage?) {
        guard image != nil else {
            return
        }
        self.contactImageView.image = image
    }

    private func resetToDefault() {
        summaryLabel.text = nil
        ratingImage.isHidden = true
        contactImageView.image = EmailListViewCell.emptyContactImage
        messageCountLabel?.isHidden = true
        threadIndicator?.isHidden = true
    }

    private func setFlagged() {
            flaggedImageView.isHidden = false
            flaggedImageView.image = UIImage(named: "icon-flagged")
    }

    private func unsetFlagged() {
        flaggedImageView.isHidden = true
    }

    private func setSeen() {
        if let font = addressLabel.font {
            let seenFont = UIFont.systemFont(ofSize: font.pointSize)
            if font != seenFont {
                setupLabels(font: seenFont)
            }
        }
    }

    private func unsetSeen() {
        if let font = addressLabel.font {
            let font = UIFont.boldSystemFont(ofSize: font.pointSize)
            setupLabels(font: font)
        }
    }

    private func setupLabels(font: UIFont) {
        addressLabel.font = font
        subjectLabel.font = font
        summaryLabel.font = font
        dateLabel.font = font
        messageCountLabel?.font = font
    }
}
