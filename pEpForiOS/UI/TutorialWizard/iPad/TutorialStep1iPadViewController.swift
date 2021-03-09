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
}

// MARK: - Layout configuration

extension TutorialStep1iPadViewController {
    private func setupLabels() {
        setupSecureTitle()
        setupSecureDescription()
        setupSecureAndTrusted()
        setupSecureAndTrustedDescription()
        setupMistrusted()
        setupMistrustedDescription()
    }

    private func setupSecureTitle() {
        secureTitle.font = titleFont
        secureTitle.text = Localized.secure
    }

    private func setupSecureDescription() {
        secureDescription.text = Localized.secureDescription
        secureDescription.font = font
    }

    private func setupSecureAndTrusted() {
        secureAndTrustedTitle.font = titleFont
        secureAndTrustedTitle.text = Localized.secureAndTrustTitle
    }

    private func setupSecureAndTrustedDescription() {
        secureAndTrustedDescription.text = Localized.secureAndTrustedDescription
        secureAndTrustedDescription.font = font
    }

    private func setupMistrusted() {
        mistrustedTitle.font = titleFont
        mistrustedTitle.text = Localized.mistrusted
    }

    private func setupMistrustedDescription() {
        mistrustedDescription.text = Localized.mistrustedDescription
        mistrustedDescription.font = font
    }
}