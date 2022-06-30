//
//  TutorialStep1ViewController.swift
//  pEp
//
//  Created by Martin Brude on 04/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class TutorialStep1iPhoneViewController: TutorialStepViewController {
    @IBOutlet private weak var secureLabel: UILabel!
    @IBOutlet private weak var secureDescriptionLabel: UILabel!
    @IBOutlet private weak var secureAndTrustedLabel: UILabel!
    @IBOutlet private weak var secureAndTrustDescription: UILabel!
    @IBOutlet private weak var mistrustedLabel: UILabel!
    @IBOutlet private weak var mistrustedDescription: UILabel!
    
    public override func configureView() {
        setBackgroundColor()
        setupSecureLabel()
        setupSecureDescriptionLabel()
        setupSecureAndTrustedLabel()
        setupSecureAndTrustedDescriptionLabel()
        setupMistrustedLabel()
        setupMistrustedDescriptionLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep1View,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewDidAppear, withEventProperties:attributes)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep1View,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewDidDisappear, withEventProperties:attributes)
    }
}

// MARK: - Layout configuration

extension TutorialStep1iPhoneViewController {

    private func setupSecureLabel() {
        secureLabel.font = titleFont
        secureLabel.text = NSLocalizedString("Secure", comment: "Secure Label - Step 1")
        secureLabel.textColor = tutorialTextColor
    }

    private func setupSecureDescriptionLabel() {
        secureDescriptionLabel.text = NSLocalizedString("With this Privacy Status all communication is Secure, but to confirm that your contact is really the person you know, you should compare Trustwords with this contact.", comment: "Secure Description Label - Step 1")
        secureDescriptionLabel.font = font
        secureDescriptionLabel.textColor = tutorialTextColor
    }

    private func setupSecureAndTrustedLabel() {
        secureAndTrustedLabel.font = titleFont
        secureAndTrustedLabel.text = NSLocalizedString("Secure & Trusted", comment: "Secure & Trusted Label - Step 1")
        secureAndTrustedLabel.textColor = tutorialTextColor
    }

    private func setupSecureAndTrustedDescriptionLabel() {
        secureAndTrustDescription.text = NSLocalizedString("When the Trustwords are confirmed to be correct and the Handshake is done, the communication will be completely secure and trusted", comment: "Secure & Trusted Description Label - Step 1")
        secureAndTrustDescription.font = font
        secureAndTrustDescription.textColor = tutorialTextColor
    }

    private func setupMistrustedLabel() {
        mistrustedLabel.font = titleFont
        mistrustedLabel.text = NSLocalizedString("Mistrusted", comment: "Mistrusted - Step 1")
        mistrustedLabel.textColor = tutorialTextColor
    }

    private func setupMistrustedDescriptionLabel() {
        mistrustedDescription.text = NSLocalizedString("If the Trustwords are not correct, there could be an attack by a man‑in‑the‑middle.", comment: "Secure & Trusted Description Label - Step 1")
        mistrustedDescription.font = font
        mistrustedDescription.textColor = tutorialTextColor
    }
}
