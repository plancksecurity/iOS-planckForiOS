//
//  TutorialStep0iPhoneViewController.swift
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
class TutorialStep0iPhoneViewController: TutorialStepViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var skipTutorialLabel: UILabel!
    @IBOutlet private weak var privacyStatusLabel: UILabel!
    @IBOutlet private weak var privacyStatusShownLabel: UILabel!
    @IBOutlet private weak var topbarLabel: UILabel!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var topbarImageView: UIImageView!

    public override func configureView() {
        setupTitleLabel()
        setupSkipTutorialLabel()
        setupPrivacyStatusLabel()
        setupPrivacyStatusShownLabel()
        setupTopbarLabel()
    }
}

// MARK: - Private

// MARK: - Layout configuration

extension TutorialStep0iPhoneViewController {
    
    private func setupTitleLabel() {
        let titleText = NSLocalizedString("Welcome to the p≡p Tutorial", comment: "Welcome to the p≡p Tutorial - Step 0")

        var foregroundColor: UIColor
        if #available(iOS 13.0, *) {
            foregroundColor = UIColor.label
        } else {
            foregroundColor = UIColor.black
        }

        let attributedString = NSMutableAttributedString(string: titleText, attributes: [
            .paragraphStyle: centeredSpaced,
            .font: titleFont,
            .foregroundColor: foregroundColor,
            .kern: 0.36
        ])
        if let range = titleText.nsRange(of: "p≡p") {
            attributedString.addAttributes([.font: titleFont, .foregroundColor: UIColor.pEpGreen], range:range)
        }
        titleLabel.attributedText = attributedString
    }
    
    private func setupSkipTutorialLabel() {
        var foregroundColor: UIColor
        if #available(iOS 13.0, *) {
            foregroundColor = UIColor.label
        } else {
            foregroundColor = UIColor.black
        }

        let text = NSLocalizedString("You can close this tutorial anytime with the Skip button.", comment: "Tutorial First text")
        let attributes : [NSAttributedString.Key : Any] = [
          .font: font,
          .foregroundColor: foregroundColor,
          .paragraphStyle: centeredSpaced,
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
        if UIDevice.isLandscape {
            privacyStatusLabel.textAlignment = .left
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
        label.textAlignment = UIDevice.isLandscape ? .left : .center
        label.attributedText = attributedText
    }
}
