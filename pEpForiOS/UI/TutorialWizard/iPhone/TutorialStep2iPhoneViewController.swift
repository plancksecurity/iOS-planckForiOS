//
//  TutorialStep2iPhoneViewController.swift
//  pEp
//
//  Created by Martin Brude on 05/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

import pEpIOSToolbox

class TutorialStep2iPhoneViewController: TutorialStepViewController {
    
    @IBOutlet private weak var secureLabel: UILabel!
    @IBOutlet private weak var truswordsLabel: UILabel!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var declineButton: UIButton!
    @IBOutlet private weak var handshakeTitle: UILabel!
    @IBOutlet private weak var privacyStatusExplanationLabel: UILabel!
    @IBOutlet private weak var confirmTrustwordsExplanationLabel: UILabel!
    @IBOutlet private weak var trustwordsContainer: UIView!

    public override func configureView() {
        setupHandshakeTitle()
        setupPrivacyStatusExplanationLabel()
        setupcCnfirmTrustwordsExplanationLabel()
        setupButtons()
        setupTrustwordsContainer()
        setupTrustwordsLabel()
        secureLabel.font = font
    }
}

// MARK: - Private - Setup View

extension TutorialStep2iPhoneViewController {

    private func setupTrustwordsLabel() {
        truswordsLabel.font = smallFont
        truswordsLabel.text = Localized.someTrustwords
    }
    
    private func setupHandshakeTitle() {
        handshakeTitle.font = titleFont
        handshakeTitle.text = Localized.handshake
    }

    private func setupPrivacyStatusExplanationLabel() {
        privacyStatusExplanationLabel.font = font
        privacyStatusExplanationLabel.text = Localized.privacyStatusIconExplanation
    }

    private func setupcCnfirmTrustwordsExplanationLabel() {
        confirmTrustwordsExplanationLabel.font = font
        confirmTrustwordsExplanationLabel.text = Localized.confirmTrustwordsExplanation
    }
    
    private func setupButtons() {
        //Confirm Button
        confirmButton.setTitle(Localized.confirmButton, for: .normal)
        confirmButton.pEpIfyForTrust(backgroundColor: .pEpGreen, textColor: .white, insetPlusHorizontal: 10, insetPlusVertical : 5, cornerRadius : 4)
        confirmButton.isUserInteractionEnabled = false
        
        //Decline Button
        declineButton.setTitle(Localized.declineButton, for: .normal)
        declineButton.pEpIfyForTrust(backgroundColor: .pEpRed, textColor: .white, insetPlusHorizontal: 10, insetPlusVertical : 5, cornerRadius : 4)
        declineButton.isUserInteractionEnabled = false
    }

    private func setupTrustwordsContainer() {
        trustwordsContainer.layer.borderWidth = 1
        trustwordsContainer.layer.borderColor = UIColor.pEpGrayBorder.withAlphaComponent(0.5).cgColor
    }
}