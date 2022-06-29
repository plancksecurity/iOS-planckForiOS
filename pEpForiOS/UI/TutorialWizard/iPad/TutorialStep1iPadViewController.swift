//
//  TutorialStep1iPadViewController.swift
//  pEp
//
//  Created by Martín Brude on 22/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import Amplitude
import pEpIOSToolbox

class TutorialStep1iPadViewController: TutorialStepViewController {

    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet private weak var secureTitle: UILabel!
    @IBOutlet private weak var secureDescription: UILabel!
    @IBOutlet private weak var secureAndTrustedTitle: UILabel!
    @IBOutlet private weak var secureAndTrustedDescription: UILabel!
    @IBOutlet private weak var mistrustedTitle: UILabel!
    @IBOutlet private weak var mistrustedDescription: UILabel!

    public override func configureView() {
        setBackgroundColor()
        setupLabels()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let date = Date()
        let dateFormatter = DateFormatter()
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep1View,
         ConstantEvents.Attributes.datetime : dateFormatter.string(from: date)
        ]
        Amplitude.instance().logEvent(ConstantEvents.ViewWasPresented, withEventProperties:attributes)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let date = Date()
        let dateFormatter = DateFormatter()
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep1View,
         ConstantEvents.Attributes.datetime : dateFormatter.string(from: date)
        ]
        Amplitude.instance().logEvent(ConstantEvents.ViewWasPresented, withEventProperties:attributes)
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
        secureTitle.textColor = tutorialTextColor
    }

    private func setupSecureDescription() {
        secureDescription.text = Localized.secureDescription
        secureDescription.font = font
        secureDescription.textColor = tutorialTextColor
    }

    private func setupSecureAndTrusted() {
        secureAndTrustedTitle.font = titleFont
        secureAndTrustedTitle.text = Localized.secureAndTrustTitle
        secureAndTrustedTitle.textColor = tutorialTextColor
    }

    private func setupSecureAndTrustedDescription() {
        secureAndTrustedDescription.text = Localized.secureAndTrustedDescription
        secureAndTrustedDescription.font = font
        secureAndTrustedDescription.textColor = tutorialTextColor
    }

    private func setupMistrusted() {
        mistrustedTitle.font = titleFont
        mistrustedTitle.text = Localized.mistrusted
        mistrustedTitle.textColor = tutorialTextColor
    }

    private func setupMistrustedDescription() {
        mistrustedDescription.text = Localized.mistrustedDescription
        mistrustedDescription.font = font
        mistrustedDescription.textColor = tutorialTextColor
    }
}
