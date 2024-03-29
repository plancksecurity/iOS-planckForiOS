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
import PlanckToolbox

final class EmailListViewCell: PEPSwipeTableViewCell, MessageViewModelConfigurable {

    static public let storyboardId = "EmailListViewCell"

    @IBOutlet weak var firstLineStackView: UIStackView!

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!

    @IBOutlet weak var flaggedImageView: UIImageView!

    @IBOutlet weak var attachmentIcon: UIImageView!
    @IBOutlet weak var contactImageView: UIImageView!

    private var viewModel: MessageViewModel?


    private let seenFontWeight: UIFont.Weight = .regular
    private let unseenFontWeight: UIFont.Weight = .bold

    private let addressFontStyle: UIFont.TextStyle = .callout
    private let subjectFontStyle: UIFont.TextStyle = .subheadline
    private let summaryFontStyle: UIFont.TextStyle = .caption1
    private let dateFontStyle: UIFont.TextStyle = .subheadline

    /**
     Original selection background color
     - Note: When a cell is selected in edit mode the background color must be the same as
     unselected.
     For that reason we need to store the original selected background color to avoid loosing it
     if we need it in the future.
     */
    private var originalBackgroundSelectionColor: UIColor?

    private var hasAttachment: Bool = false {
        didSet {
            if hasAttachment {
                attachmentIcon.isHidden = false
            } else {
                attachmentIcon.isHidden = true
            }
        }
    }

    public var isFlagged: Bool = false {
        didSet {
            if isFlagged {
                setFlagged()
            } else {
                unsetFlagged()
            }
        }
    }

    public var isSeen: Bool = false {
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
        setBackgroundSelectionColor()
        contactImageView.applyContactImageCornerRadius()
        resetToDefault()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clear()
        resetToDefault()
    }

    public func configure(for viewModel: MessageViewModel) {
        self.viewModel = viewModel

        // Occupy space in any case. Otherwise the summary might be filled
        // _after_ this function has ended and the cell has already been
        // layouted, leading to a smaller cell than usual.
        summaryLabel.text = " "
        summaryLabel.font = UIFont.planckFont(style: summaryFontStyle, weight: seenFontWeight)
        addressLabel.font = UIFont.planckFont(style: addressFontStyle, weight: viewModel.isSeen ? seenFontWeight : unseenFontWeight)
        addressLabel.text = atLeastOneSpace(possiblyEmptyString: viewModel.displayedUsername)
        subjectLabel.font = UIFont.planckFont(style: subjectFontStyle, weight: viewModel.isSeen ? seenFontWeight : unseenFontWeight)
        subjectLabel.text = atLeastOneSpace(possiblyEmptyString: viewModel.subject)
        dateLabel.font = UIFont.planckFont(style: dateFontStyle, weight: viewModel.isSeen ? seenFontWeight : unseenFontWeight)

        if !viewModel.isSeen {
            contactImageView.applyBorder(color: .label)
        } else {
            contactImageView.removeBorder()
        }

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
    }

    public func clear() {
        guard let vm = viewModel else {
            //Nothing to do 
            return
        }
        vm.unsubscribeForUpdates()
        viewModel = nil
    }
}

// MARK: - Private

extension EmailListViewCell {

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

    private func setContactImage(image: UIImage?) {
        guard image != nil else {
            return
        }
        self.contactImageView.image = image
    }

    private func resetToDefault() {
        clear()
        summaryLabel.text = nil
        contactImageView.image = EmailListViewCell.emptyContactImage
        tintColor = UIColor.primary()
    }

    private func setFlagged() {
        flaggedImageView.isHidden = false
        flaggedImageView.image = UIImage(named: "icon-flagged")
    }

    private func unsetFlagged() {
        flaggedImageView.isHidden = true
    }

    private func setSeen() {
        setupLabels(seen: true)
    }

    private func unsetSeen() {
        setupLabels(seen: false)
    }

    private func setupLabels(seen: Bool) {
        let fontWeight: UIFont.Weight = seen
            ? seenFontWeight
            : unseenFontWeight
        addressLabel.font = UIFont.planckFont(style: addressFontStyle,
                                           weight: fontWeight)
        subjectLabel.font = UIFont.planckFont(style: subjectFontStyle,
                                           weight: fontWeight)
        summaryLabel.font = UIFont.planckFont(style: summaryFontStyle,
                                           weight: fontWeight)
        dateLabel.font = UIFont.planckFont(style: dateFontStyle,
                                        weight: fontWeight)
    }

    /// This method highlights the cell that is being pressed.
    /// - Note: We only accept this if the cell is not in edit mode.
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if !isEditing {
            super.setHighlighted(highlighted, animated: animated)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)
        /// Instead of the default highlighting background, use a different color for this view.
        let viewForHighlight = UIView()
        selectedBackgroundView = viewForHighlight
        viewForHighlight.backgroundColor = originalBackgroundSelectionColor
    }

    /// - Returns: " " (a space) instead of an empty String, otherwise the original String
    /// unchanged.
    private func atLeastOneSpace(possiblyEmptyString: String) -> String {
        if possiblyEmptyString == "" {
            return " "
        } else {
            return possiblyEmptyString
        }
    }

    private func setBackgroundSelectionColor() {
        originalBackgroundSelectionColor = UIColor.pEpGreyBackground
        if UITraitCollection.current.userInterfaceStyle == .dark {
            originalBackgroundSelectionColor = UIColor.systemGray5
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            setBackgroundSelectionColor()
        }
    }
}
