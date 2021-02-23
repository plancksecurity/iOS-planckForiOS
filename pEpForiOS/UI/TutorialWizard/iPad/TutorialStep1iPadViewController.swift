//
//  TutorialStep1iPadViewController.swift
//  pEp
//
//  Created by Martín Brude on 22/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

class TutorialStep1iPadViewController: TutorialStepViewController {

    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet private weak var secureTitle: UILabel!
    @IBOutlet private weak var secureDescription: UILabel!
    @IBOutlet private weak var secureAndTrustedTitle: UILabel!
    @IBOutlet private weak var secureAndTrustedDescription: UILabel!
    @IBOutlet private weak var mistrustedTitle: UILabel!
    @IBOutlet private weak var mistrustedDescription: UILabel!


    public override func configureView() {
        setupLabels()
    }

    private func setupLabels() {
        setupSecureTitle()
        setupSecureDescription()
        setupSecureAndTrusted()
        setupSecureAndTrustedDescription()
        setupMistrusted()
        setupMistrustedDescription()
    }
}

// MARK: - Layout configuration

extension TutorialStep1iPadViewController {

    private func setupSecureTitle() {
        secureTitle.font = titleFont
        secureTitle.text = NSLocalizedString("Secure", comment: "Secure Label - Step 1")
    }

    private func setupSecureDescription() {
        secureDescription.text = NSLocalizedString("With this Privacy Status all communication is Secure, but to confirm that your contact is really the person you know, you should compare Trustwords with this contact.", comment: "Secure Description Label - Step 1")
        secureDescription.font = font
    }

    private func setupSecureAndTrusted() {
        secureAndTrustedTitle.font = titleFont
        secureAndTrustedTitle.text = NSLocalizedString("Secure & Trusted", comment: "Secure & Trusted Label - Step 1")
    }

    private func setupSecureAndTrustedDescription() {
        secureAndTrustedDescription.text = NSLocalizedString("When the Trustwords are confirmed to be correct and the Handshake is done, the communication will be completely secure and trusted", comment: "Secure & Trusted Description Label - Step 1")
        secureAndTrustedDescription.font = font
    }

    private func setupMistrusted() {
        mistrustedTitle.font = titleFont
        mistrustedTitle.text = NSLocalizedString("Mistrusted", comment: "Mistrusted - Step 1")
    }

    private func setupMistrustedDescription() {
        mistrustedDescription.text = NSLocalizedString("If the Trustwords are not correct, there could be an attack by a man‑in‑the‑middle.", comment: "Secure & Trusted Description Label - Step 1")
        mistrustedDescription.font = font
    }
}
