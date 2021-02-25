//
//  TutorialStep2iPadViewController.swift
//  pEp
//
//  Created by Martín Brude on 24/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

class TutorialStep2iPadViewController : TutorialStepViewController {

    @IBOutlet private weak var handshakeTitle: UILabel!
    @IBOutlet private weak var trustwords: UILabel!
    @IBOutlet private weak var declineButton: TrustwordsButton!
    @IBOutlet private weak var confirmButton: TrustwordsButton!
    @IBOutlet private weak var privacyStatusExplanation: UILabel!
    @IBOutlet private weak var confirmTrustwordsExplanation: UILabel!

    public override func configureView() {
        setupHandshakeTitle()
        setupTrustwordsLabel()
        setupTrustButtons()
        setupPrivacyStatusExplanationLabel()
        setupcCnfirmTrustwordsExplanationLabel()
    }

    private func setupHandshakeTitle() {
        handshakeTitle.font = titleFont
        handshakeTitle.text = NSLocalizedString("Handshake", comment: "Title of the view")
    }

    private func setupTrustwordsLabel() {
        trustwords.font = smallFont
        trustwords.text = NSLocalizedString("OUTDISTANCE   CORRINA   ETHIOPIA    OUTDRAW   FLEECER", comment: "Some trustwords")
    }

    private func setupTrustButtons() {
        confirmButton.buttonTitle = NSLocalizedString("Confirm", comment: "Confirm correct trustwords/PGP fingerprint")
        declineButton.buttonTitle = NSLocalizedString("Decline", comment: "Incorrect trustwords/PGP fingerprint")
    }

    private func setupPrivacyStatusExplanationLabel() {
        privacyStatusExplanation.font = font
        privacyStatusExplanation.text = NSLocalizedString("When you click on the Privacy Status icon in the top bar, you will get to Handshake, where you can verify your communication parner.", comment: "Privacy status explanation Label")
    }

    private func setupcCnfirmTrustwordsExplanationLabel() {
        confirmTrustwordsExplanation.font = font
        confirmTrustwordsExplanation.text = NSLocalizedString("When you confirm that the Trustwords of your communication partner are correct, your communication will be completely Secure & Trusted.", comment: "Confirm Trustwords explanation Label")
    }
}
