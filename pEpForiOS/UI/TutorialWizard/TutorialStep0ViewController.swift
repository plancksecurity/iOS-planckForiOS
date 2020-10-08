//
//  TutorialStep0ViewController.swift
//  pEp
//
//  Created by Martin Brude on 27/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

/// ViewController that configures the layout of the first step of the tutorial.
/// It basically set the texts and it's properties.
/// The layout differences regarding the device orientation and screen size are configured
/// in storyboard using size classes.
class TutorialStep0ViewController: TutorialStepViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var skipTutorialLabel: UILabel!
    @IBOutlet private weak var privacyStatusLabel: UILabel!
    @IBOutlet private weak var privacyStatusShownLabel: UILabel!
    @IBOutlet private weak var topbarLabel: UILabel!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var topbarImageView: UIImageView!
    
    // We manipulate constraints to support iPad orientations as this inherits from CustomTraitCollectionViewController,
    @IBOutlet private weak var topbarWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabelLeadingContraint: NSLayoutConstraint!
    @IBOutlet weak private var topbarLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenPrivacyStatusAndSkipConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenTitleViewAndTopConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenSkipAndTitleConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenAvatarAndPrivacyStatus2LabelConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenTopbarLabelAndPrivacyStatus2Constraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenTopbarImageAndBottomLabelConstraint: NSLayoutConstraint!
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        adjustConstraintsIfNeeded()
    }
   
    public override func configureView() {
        setupTitleLabel()
        setupSkipTutorialLabel()
        setupPrivacyStatusLabel()
        setupPrivacyStatusShownLabel()
        setupTopbarLabel()
    }
}

// MARK: - Private

// MARK: - Constraints adjustments

extension TutorialStep0ViewController {

    private struct Constants {
        struct Portrait {
            static let skipTitleDistance : CGFloat = 70.0
            static let titleViewTopDistance : CGFloat = 50.0
            static let privacyStatusSkipDistance : CGFloat = 26.0
            static let avatarPrivacyStatus2Distance : CGFloat = 30.0
            static let titleLabelLeading : CGFloat = 170.0
            static let privacyStatus2Leading: CGFloat = 170.0
            static let distanceBetweenTopbarLabelAndPrivacyStatus2: CGFloat = 120.0
            static let distanceBetweenTopbarImageAndBottomLabel: CGFloat = 50.0
            static let topbarLabelLeadingConstraint: CGFloat = 20.0
            static let topbarWidth: CGFloat = 500.0

        }
        struct Landscape {
            static let skipTitleDistance: CGFloat = 26.0
            static let titleViewTopDistance: CGFloat = 35.0
            static let privacyStatusSkipDistance: CGFloat = 19.0
            static let avatarPrivacyStatus2Distance: CGFloat = 15.5
            static let titleLabelLeading: CGFloat = 50.0
            static let privacyStatus2Leading: CGFloat = 80.0
            static let distanceBetweenTopbarLabelAndPrivacyStatus2: CGFloat = 100.0
            static let distanceBetweenTopbarImageAndBottomLabel: CGFloat = 20.0
            static let topbarLabelLeadingConstraint: CGFloat = 80.0
            static let topbarWidth: CGFloat = 500.0
        }
    }
    
    private func adjustConstraintsIfNeeded() {
        guard let superView = view.superview, isIpad else {
            Log.shared.info("Superview is missing or is not needed to adjust constraints here")
            return
        }

        let avatarSize = isLandscape ? CGSize(width: 100, height: 100) : CGSize(width: 78, height: 78)
        avatarImageView.image = avatarImageView.image?.resizeImage(targetSize: avatarSize)
        distanceBetweenSkipAndTitleConstraint.constant = isLandscape ? Constants.Landscape.skipTitleDistance : Constants.Portrait.skipTitleDistance
        distanceBetweenTitleViewAndTopConstraint.constant = isLandscape ? Constants.Landscape.titleViewTopDistance : Constants.Portrait.titleViewTopDistance
        distanceBetweenPrivacyStatusAndSkipConstraint.constant = isLandscape ? Constants.Landscape.privacyStatusSkipDistance : Constants.Portrait.privacyStatusSkipDistance
        titleLabelLeadingContraint.constant = isLandscape ? Constants.Landscape.titleLabelLeading : Constants.Portrait.titleLabelLeading
        distanceBetweenTopbarLabelAndPrivacyStatus2Constraint.constant = isLandscape ? Constants.Landscape.distanceBetweenTopbarLabelAndPrivacyStatus2 :
            Constants.Portrait.distanceBetweenTopbarLabelAndPrivacyStatus2
        distanceBetweenTopbarImageAndBottomLabelConstraint.constant = isLandscape ? Constants.Landscape.distanceBetweenTopbarImageAndBottomLabel :
            Constants.Portrait.distanceBetweenTopbarImageAndBottomLabel
        topbarLabelLeadingConstraint.constant = isLandscape ? Constants.Landscape.topbarLabelLeadingConstraint : Constants.Portrait.topbarLabelLeadingConstraint
        topbarWidthConstraint.isActive = true
        topbarWidthConstraint.constant = isLandscape ? Constants.Landscape.topbarWidth : Constants.Portrait.topbarWidth
        
        superView.layoutIfNeeded()
    }
}

// MARK: - Layout configuration

extension TutorialStep0ViewController {
    
    private func setupTitleLabel() {
        let titleText = NSLocalizedString("Welcome to the p≡p Tutorial", comment: "Welcome to the p≡p Tutorial - Step 0")
        let attributedString = NSMutableAttributedString(string: titleText, attributes: [
            .paragraphStyle: spaced,
            .font: titleFont,
            .foregroundColor: UIColor.black,
            .kern: 0.36
        ])
        if let range = titleText.nsRange(of: "p≡p") {
            attributedString.addAttributes([.font: titleFont, .foregroundColor: UIColor.pEpGreen], range:range)
        }
        titleLabel.attributedText = attributedString
    }
    
    private func setupSkipTutorialLabel() {
        let text = NSLocalizedString("You can close this tutorial anytime with the Skip button.", comment: "Tutorial First text")
        let attributes : [NSAttributedString.Key : Any] = [
          .font: font,
          .foregroundColor: UIColor.black,
          .paragraphStyle: centered,
          .kern: 0.2]
        skipTutorialLabel.attributedText = NSMutableAttributedString(string:text, attributes: attributes)
    }
    
    private func setupPrivacyStatusLabel() {
        let text = NSLocalizedString("p≡p uses a Privacy Status icon to indicate how secure your communication is.", comment: "Tutorial Second text")
        let attributedText = NSMutableAttributedString(string:text)
        if let range = text.nsRange(of: "p≡p") {
            attributedText.addAttributes([.font: font, .foregroundColor: UIColor.pEpGreen], range: range)
            attributedText.addAttributes(textAttributes, range: NSRange(location: range.location + range.length, length: text.count - range.length))
        }
        privacyStatusLabel.attributedText = attributedText
    }
    
    private func setupPrivacyStatusShownLabel() {
        let text = NSLocalizedString("This Privacy Status is shown as an icon the user´s avatars:", comment: "Tutorial Third text")
        set(text, on: privacyStatusShownLabel)
    }
    
    private func setupTopbarLabel() {
        let text = NSLocalizedString("And in the top bar when you open or write an email:", comment: "Tutorial Fourth text")
        set(text, on: topbarLabel)
    }
    
    private func set(_ text : String, on label : UILabel) {
        let attributedText = NSMutableAttributedString(string:text)
        attributedText.addAttributes(textAttributes, range: NSRange(location: 0, length: text.count))
        label.textAlignment = isLandscape ? .left : .center
        label.attributedText = attributedText
    }
}
