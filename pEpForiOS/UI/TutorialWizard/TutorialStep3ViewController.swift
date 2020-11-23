//
//  TutorialStep3ViewController.swift
//  pEp
//
//  Created by Martin Brude on 11/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

class TutorialStep3ViewController: TutorialStepViewController {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var explanationLabel: UILabel!
    @IBOutlet private weak var commonDenominatorLabel: UILabel!
    @IBOutlet private weak var imageWidth: NSLayoutConstraint!
    public override func configureView() {
        setupTitleLabel()
        setupExplanationLabel()
        setupCommonDenominatorLabel()
    }
    
    private func setupTitleLabel() {
        titleLabel.text = NSLocalizedString("Privacy Status", comment: "Privacy Status Label")
        titleLabel.font = titleFont
    }
    
    private func setupExplanationLabel() {
        explanationLabel.text = NSLocalizedString("The icon in the top bar reflects the Privacy Status of the message, which is the lowest lowest common denominator of all communication partners of that message, for example:", comment: "Privacy Status Explanation")
        explanationLabel.font = font
    }
    
    private func setupCommonDenominatorLabel() {
        commonDenominatorLabel.text = NSLocalizedString("In this case the Privacy Status of the message is Secure, because this is the lowest common denominator of the two communication partners.", comment: "Privacy Status - Common Denominator Explanation")
        commonDenominatorLabel.font = font
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        adjustConstraintsIfNeeded()
    }
    
    private func adjustConstraintsIfNeeded() {
        guard let superView = view.superview, UIDevice.isIpad else {
            Log.shared.info("Superview is missing or is not needed to adjust constraints here")
            return
        }
        
        imageWidth.constant = 334
        superView.layoutIfNeeded()
    }
}
