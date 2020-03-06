//
//  TutorialStep2ViewController.swift
//  pEp
//
//  Created by Martin Brude on 05/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class TutorialStep2ViewController: TutorialStepViewController {
    
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var declineButton: UIButton!
    @IBOutlet private weak var handshakeTitle: UILabel!
    @IBOutlet private weak var privacyStatusExplanationLabel: UILabel!
    @IBOutlet private weak var confirmTrustwordsExplanationLabel: UILabel!
    @IBOutlet weak var trustwordsContainer: UIView!
    
    
    public override func configureView() {
        setupHandshakeTitle()
        setupPrivacyStatusExplanationLabel()
        setupcCnfirmTrustwordsExplanationLabel()
        trustwordsContainer.layer.borderWidth = 1
        trustwordsContainer.layer.borderColor = UIColor.pEpGrayBorder.withAlphaComponent(0.5).cgColor

        //Confirm Button
        let confirmTitle = NSLocalizedString("Confirm", comment: "Confirm correct trustwords/PGP fingerprint")
        confirmButton.setTitle(confirmTitle, for: .normal)
        confirmButton.pEpIfyForTrust(backgroundColor: .pEpGreen, textColor: .white)
        //Decline Button
        let declineTitle = NSLocalizedString("Decline", comment: "Incorrect trustwords/PGP fingerprint")
        declineButton.setTitle(declineTitle, for: .normal)
        declineButton.pEpIfyForTrust(backgroundColor: .pEpRed, textColor: .white)
    }
    
    private func setupHandshakeTitle() {
        handshakeTitle.font = titleFont
        handshakeTitle.text = "Handshake".localized()
    }

    private func setupPrivacyStatusExplanationLabel() {
        privacyStatusExplanationLabel.font = font
        privacyStatusExplanationLabel.text = "When you click on the Privacy Status icon in the top bar, you will get to Handshake, where you can verify your communication parner.".localized()
    }

    private func setupcCnfirmTrustwordsExplanationLabel() {
        confirmTrustwordsExplanationLabel.font = font
        confirmTrustwordsExplanationLabel.text = "When you confirm that the Trustwords of your communication partner are correct, your communication will be completely Secure & Trusted.".localized()
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustConstraintsIfNeeded()
    }
}

extension TutorialStep2ViewController {

    func adjustConstraintsIfNeeded() {
        guard let superView = view.superview, isIpad else {
            Log.shared.info("Superview is missing or is not needed to adjust constraints here")
            return
        }

        superView.layoutIfNeeded()
    }
    
    private struct Constants {
        struct Portrait {

        }

        struct Landscape {

        }
    }
}
