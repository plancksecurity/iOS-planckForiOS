//
//  TutorialStep3iPadViewController.swift
//  pEp
//
//  Created by Martín Brude on 25/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

class TutorialStep3iPadViewController: TutorialStepViewController {
    @IBOutlet weak var privacyStatusLabel: UILabel!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var commonDenominatorLabel: UILabel!

    public override func configureView() {
        setupTitleLabel()
        setupExplanationLabel()
        setupCommonDenominatorLabel()
    }

    private func setupTitleLabel() {
        privacyStatusLabel.text = NSLocalizedString("Privacy Status", comment: "Privacy Status Label")
        privacyStatusLabel.font = titleFont
    }

    private func setupExplanationLabel() {
        explanationLabel.text = NSLocalizedString("The icon in the top bar reflects the Privacy Status of the message, which is the lowest lowest common denominator of all communication partners of that message, for example:", comment: "Privacy Status Explanation")
        explanationLabel.font = font
    }

    private func setupCommonDenominatorLabel() {
        commonDenominatorLabel.text = NSLocalizedString("In this case the Privacy Status of the message is Secure, because this is the lowest common denominator of the two communication partners.", comment: "Privacy Status - Common Denominator Explanation")
        commonDenominatorLabel.font = font
    }
}
