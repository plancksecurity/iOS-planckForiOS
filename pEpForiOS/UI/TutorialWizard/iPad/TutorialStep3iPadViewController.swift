//
//  TutorialStep3iPadViewController.swift
//  pEp
//
//  Created by Martín Brude on 25/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import Amplitude
import pEpIOSToolbox

class TutorialStep3iPadViewController: TutorialStepViewController {
    @IBOutlet private weak var privacyStatusLabel: UILabel!
    @IBOutlet private weak var explanationLabel: UILabel!
    @IBOutlet private weak var commonDenominatorLabel: UILabel!

    public override func configureView() {
        setBackgroundColor()
        setupTitleLabel()
        setupExplanationLabel()
        setupCommonDenominatorLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let date = Date()
        let dateFormatter = DateFormatter()
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep3View,
         ConstantEvents.Attributes.datetime : dateFormatter.string(from: date)
        ]
        Amplitude.instance().logEvent(ConstantEvents.ViewWasPresented, withEventProperties:attributes)
    }

    private func setupTitleLabel() {
        privacyStatusLabel.text = Localized.privacyStatusTitle
        privacyStatusLabel.font = titleFont
        privacyStatusLabel.textColor = tutorialTextColor
    }

    private func setupExplanationLabel() {
        explanationLabel.text = Localized.privacyStatusExplanation
        explanationLabel.font = font
        explanationLabel.textColor = tutorialTextColor
    }

    private func setupCommonDenominatorLabel() {
        commonDenominatorLabel.text = Localized.commonDenominator
        commonDenominatorLabel.font = font
        commonDenominatorLabel.textColor = tutorialTextColor
    }
}
