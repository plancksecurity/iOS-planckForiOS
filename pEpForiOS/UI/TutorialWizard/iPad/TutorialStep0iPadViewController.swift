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
class TutorialStep0iPadViewController: TutorialStepViewController {

    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet private weak var welcomeTitle: UILabel!
    @IBOutlet private weak var skipTutorial: UILabel!
    @IBOutlet private weak var privacyStatus: UILabel!
    @IBOutlet private weak var privacyStatusDescription: UILabel!
    @IBOutlet private weak var topbar: UILabel!
    @IBOutlet private weak var stackViewHeight: NSLayoutConstraint!

    public override func configureView() {
        setupLabels()
    }

    private func setupLabels() {
        setupTitle()
        setupSkipTutorial()
        setupPrivacyStatus()
        setupPrivacyStatusDescription()
        setupTopbar()
    }
}

// MARK: - Layout configuration

extension TutorialStep0iPadViewController {

    private func setupTitle() {
        let titleText = NSLocalizedString("Welcome to the p≡p Tutorial", comment: "Welcome to the p≡p Tutorial - Step 0")
        let attributedString = NSMutableAttributedString(string: titleText, attributes: [
            .font: titleFont,
            .foregroundColor: UIColor.black,
        ])
        if let range = titleText.nsRange(of: "p≡p") {
            attributedString.addAttributes([.font: titleFont, .foregroundColor: UIColor.pEpGreen], range:range)
        }
        welcomeTitle.attributedText = attributedString
    }

    private func setupSkipTutorial() {
        let text = NSLocalizedString("You can close this tutorial anytime with the Skip button.", comment: "Tutorial First text")
        let attributes : [NSAttributedString.Key : Any] = [
          .font: font,
          .foregroundColor: UIColor.black,
          .paragraphStyle: UIDevice.isIpadSmall ? centered : centeredSpaced,
        ]
        skipTutorial.attributedText = NSMutableAttributedString(string:text, attributes: attributes)
    }

    private func setupPrivacyStatus() {
        let text = NSLocalizedString("p≡p uses a Privacy Status icon to indicate how secure your communication is.", comment: "Tutorial Second text")
        let attributedText = NSMutableAttributedString(string:text)
        if let range = text.nsRange(of: "p≡p") {
            attributedText.addAttributes([.font: font, .foregroundColor: UIColor.pEpGreen], range: range)
            attributedText.addAttributes(textAttributes, range: NSRange(location: range.location + range.length, length: text.count - range.length))
        }
        privacyStatus.attributedText = attributedText
    }

    private func setupPrivacyStatusDescription() {
        let text = NSLocalizedString("This Privacy Status is shown as an icon the user´s avatars:", comment: "Tutorial Third text")
        set(text, on: privacyStatusDescription)
    }

    private func setupTopbar() {
        let text = NSLocalizedString("And in the top bar when you open or write an email:", comment: "Tutorial Fourth text")
        set(text, on: topbar)
    }

    private func set(_ text : String, on label : UILabel) {
        let attributedText = NSMutableAttributedString(string:text)
        attributedText.addAttributes(textAttributes, range: text.wholeRange())
        label.attributedText = attributedText
    }
}
