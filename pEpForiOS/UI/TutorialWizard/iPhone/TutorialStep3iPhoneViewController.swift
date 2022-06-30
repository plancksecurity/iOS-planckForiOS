//
//  TutorialStep3iPhoneViewController.swift
//  pEp
//
//  Created by Martin Brude on 11/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class TutorialStep3iPhoneViewController: TutorialStepViewController {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var explanationLabel: UILabel!
    @IBOutlet private weak var commonDenominatorLabel: UILabel!
    @IBOutlet private weak var imageWidth: NSLayoutConstraint!

    public override func configureView() {
        setBackgroundColor()
        setupTitleLabel()
        setupExplanationLabel()
        setupCommonDenominatorLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep3View,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewWasPresented, withEventProperties:attributes)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

                
        let attributes =
        [ConstantEvents.Attributes.viewName : ConstantEvents.ViewNames.TutorialStep3View,
         ConstantEvents.Attributes.datetime : Date.getCurrentDatetimeAsString()
        ]
        EventTrackingUtil.shared.logEvent(ConstantEvents.ViewWasDismissed, withEventProperties:attributes)
    }

    private func setupTitleLabel() {
        titleLabel.text = Localized.privacyStatusTitle 
        titleLabel.font = titleFont
        titleLabel.textColor = tutorialTextColor
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
