//
//  TutorialStep2iPadViewController.swift
//  pEp
//
//  Created by Martín Brude on 24/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class TutorialStep2iPadViewController : TutorialStepViewController {

    @IBOutlet private weak var handshakeTitle: UILabel!
    @IBOutlet private weak var trustwords: UILabel!
    @IBOutlet private weak var declineButton: TrustwordsButton!
    @IBOutlet private weak var confirmButton: TrustwordsButton!
    @IBOutlet private weak var privacyStatusExplanation: UILabel!
    @IBOutlet private weak var confirmTrustwordsExplanation: UILabel!

    public override func configureView() {
        setBackgroundColor()
        setupHandshakeTitle()
        setupTrustwordsLabel()
        setupTrustButtons()
        setupPrivacyStatusExplanationLabel()
        setupcCnfirmTrustwordsExplanationLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep2View,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewDidAppear, withEventProperties:attributes)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep2View,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewDidDisappear, withEventProperties:attributes)
    }

    private func setupHandshakeTitle() {
        handshakeTitle.font = titleFont
        handshakeTitle.text = Localized.handshake
        handshakeTitle.textColor = tutorialTextColor
    }

    private func setupTrustwordsLabel() {
        trustwords.font = smallFont
        trustwords.text = Localized.someTrustwords
        trustwords.textColor = tutorialTextColor
    }

    private func setupTrustButtons() {
        confirmButton.buttonTitle = Localized.confirmButton
        declineButton.buttonTitle = Localized.declineButton
    }

    private func setupPrivacyStatusExplanationLabel() {
        privacyStatusExplanation.font = font
        privacyStatusExplanation.text = Localized.privacyStatusIconExplanation
        privacyStatusExplanation.textColor = tutorialTextColor
    }

    private func setupcCnfirmTrustwordsExplanationLabel() {
        confirmTrustwordsExplanation.font = font
        confirmTrustwordsExplanation.text = Localized.confirmTrustwordsExplanation
        confirmTrustwordsExplanation.textColor = tutorialTextColor
    }
}
