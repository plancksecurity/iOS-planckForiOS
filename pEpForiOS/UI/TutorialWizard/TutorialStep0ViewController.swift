//
//  TutorialStep0ViewController.swift
//  pEp
//
//  Created by Martin Brude on 27/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

/// ViewController that configures the layout of the first step of the tutorial.
/// It basically set the texts and it's properties.
/// The layout differences regarding the device orientation and screen size are configured
/// in storyboard using size classes.
class TutorialStep0ViewController: TutorialStepViewController {
    
    @IBOutlet weak private var titleLabelLeadingContraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var skipTutorialLabel: UILabel!
    @IBOutlet private weak var privacyStatusLabel: UILabel!
    @IBOutlet private weak var privacyStatusShownLabel: UILabel!
    @IBOutlet private weak var topbarLabel: UILabel!
    
    //Contraints
    @IBOutlet weak var bottomLabelLeadingContraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenPrivacyStatusAndSkipTutorialLabels: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenTitleViewAndTopConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenPrivacyStatusAndSkipTutorialLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenAvatarImageAndPrivacyStatusShownLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak private var privacyStatusShownLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenBottomLabelAndPrivacyStatusIconLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak private var distanceBetweenTopbarImageAndBottomLabel: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
    private func adjustConstraintsIfNeeded() {
        guard let superView = view.superview, isIpad && !isLandscape else {
            Log.shared.error("Superview is missing or is not needed to adjust constraints here")
            return
        }
        distanceBetweenPrivacyStatusAndSkipTutorialLabelConstraint.constant = 50.0
        distanceBetweenTitleViewAndTopConstraint.constant = 50.0
        distanceBetweenPrivacyStatusAndSkipTutorialLabels.constant = 30.0
        distanceBetweenAvatarImageAndPrivacyStatusShownLabelConstraint.constant = 30.0
        titleLabelLeadingContraint.constant = 170.0
        privacyStatusShownLabelLeadingConstraint.constant = 170.0
        distanceBetweenBottomLabelAndPrivacyStatusIconLabelConstraint.constant = 120.0
        distanceBetweenTopbarImageAndBottomLabel.constant = 50.0
        bottomLabelLeadingContraint.constant = 120
        superView.layoutIfNeeded()
    }
}

// MARK: - Labels configuration

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
