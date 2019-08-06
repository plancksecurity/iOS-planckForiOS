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

class EmailListViewCell: PEPSwipeTableViewCell, MessageViewModelConfigurable {
    public static let storyboardId = "EmailListViewCell"

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    @IBOutlet weak var flaggedImageView: UIImageView!

    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var attachmentIcon: UIImageView!
    @IBOutlet weak var contactImageView: UIImageView!

    /**
     Fake constraint for IB to be happy.
     - Note: This gets deactivated on runtime.
     */
    @IBOutlet weak var fakeRatingImageToContactImageVertical: NSLayoutConstraint?

    /**
     Fake constraint for IB to be happy.
     - Note: This gets deactivated on runtime.
     */
    @IBOutlet weak var fakeRatingImageToContactImageHorizontal: NSLayoutConstraint?

    private var viewModel: MessageViewModel?

    /**
     Original selection background color
     - Note: When a cell is selected in edit mode the background color must be the same as
     unselected.
     For that reason we need to store the original selected background color to avoid loosing it
     if we need it in the future.
     */
    private var originalBackgroundSelectionColor: UIColor?

    private var hasAttachment:Bool = false {
        didSet {
            if hasAttachment {
                attachmentIcon.isHidden = false
            } else {
                attachmentIcon.isHidden = true
            }
        }
    }

    public var isFlagged:Bool = false {
        didSet {
            if isFlagged {
                setFlagged()
            } else {
                unsetFlagged()
            }
        }
    }

    public var isSeen:Bool = false {
        didSet {
            if isSeen {
                setSeen()
            } else {
                unsetSeen()
            }
        }
    }

    // MARK: - View overrides (life cycle etc.)

    override func awakeFromNib() {
        super.awakeFromNib()
        originalBackgroundSelectionColor = selectedBackgroundView?.backgroundColor
        contactImageView.applyContactImageCornerRadius()
        resetToDefault()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clear()
        resetToDefault()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let constr = fakeRatingImageToContactImageVertical {
            constr.isActive = false
        }
        if let constr = fakeRatingImageToContactImageHorizontal {
            constr.isActive = false
        }

        ratingImage.centerXAnchor.constraint(
            equalTo: contactImageView.rightAnchor).isActive = true
        ratingImage.centerYAnchor.constraint(
            equalTo: contactImageView.bottomAnchor).isActive = true
    }

    public func configure(for viewModel: MessageViewModel) {
        self.viewModel = viewModel

        // Occupy space in any case. Otherwise the summary might be filled
        // _after_ this function has ended and the cell has already been
        // layouted, leading to a smaller cell than usual.
        summaryLabel.text = " "

        addressLabel.text = atLeastOneSpace(possiblyEmptyString: viewModel.displayedUsername)
        subjectLabel.text = atLeastOneSpace(possiblyEmptyString: viewModel.subject)

        viewModel.bodyPeekCompletion = { [weak self] bodyPeek in
            self?.summaryLabel.text = bodyPeek == "" ? " " : bodyPeek
        }

        isFlagged = viewModel.isFlagged
        isSeen = viewModel.isSeen

        hasAttachment = viewModel.showAttchmentIcon
        dateLabel.text = viewModel.dateText

        // Message threading is not supported. Let's keep it for now. It might be helpful for
        // reimplementing.
        //        configureThreadIndicator(for: viewModel)

        if viewModel.senderContactImage != nil {
            setContactImage(image: viewModel.senderContactImage)
        } else {
            viewModel.getProfilePicture { [weak self] image in
                self?.setContactImage(image: image)
            }
        }

        viewModel.getSecurityBadge { [weak self] image in
            DispatchQueue.main.async {
                self?.setPepRatingImage(image: image)
            }
        }
    }

    public func clear() {
        viewModel?.unsubscribeForUpdates()
    }
}

// MARK: - Private

extension EmailListViewCell {

    private static var flaggedImage: UIImage? = nil
    private static var emptyContactImage = UIImage(named: "empty-avatar")

    // Message threading is not supported. Let's keep it for now. It might be helpful for
    // reimplementing.
    //    private func configureThreadIndicator(for viewModel: MessageViewModel) {
    //        guard let _ = messageCountLabel,
    //            let _ = threadIndicator else {
    //                messageCount = 0
    //                return
    //        }
    //        viewModel.messageCount { (messageCount) in
    //            self.messageCount = messageCount
    //        }
    //
    //    }

    private func setPepRatingImage(image: UIImage?) {
        if ratingImage.image != image {
            self.ratingImage.image = image
            self.ratingImage.isHidden = (image == nil)
        }
    }

    private func setContactImage(image: UIImage?) {
        guard image != nil else {
            return
        }
        self.contactImageView.image = image
    }

    private func resetToDefault() {
        viewModel?.unsubscribeForUpdates()
        viewModel = nil
        summaryLabel.text = nil
        ratingImage.isHidden = true
        ratingImage.image = nil
        contactImageView.image = EmailListViewCell.emptyContactImage
        tintColor = UIColor.pEpGreen
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
    }


    ///This method highlights the cell that is being pressed.
    ///- Note: We only accept this if the cell is not in edit mode.
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if !isEditing {
            super.setHighlighted(highlighted, animated: animated)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)
        let viewForHighlight = UIView()
        self.selectedBackgroundView = viewForHighlight
        if self.isEditing {
            viewForHighlight.backgroundColor = UIColor.clear
        } else {
            viewForHighlight.backgroundColor = originalBackgroundSelectionColor
        }
    }

    ///- Returns: " " (a space) instead of an empty String, otherwise the original String
    ///unchanged.
    private func atLeastOneSpace(possiblyEmptyString: String) -> String {
        if possiblyEmptyString == "" {
            return " "
        } else {
            return possiblyEmptyString
        }
    }
}
