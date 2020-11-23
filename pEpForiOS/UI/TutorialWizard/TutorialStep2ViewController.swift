//
//  TutorialStep2ViewController.swift
//  pEp
//
//  Created by Martin Brude on 05/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

import pEpIOSToolbox

class TutorialStep2ViewController: TutorialStepViewController {
    
    @IBOutlet private weak var secureLabel: UILabel!
    @IBOutlet private weak var truswordsLabel: UILabel!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var declineButton: UIButton!
    @IBOutlet private weak var handshakeTitle: UILabel!
    @IBOutlet private weak var privacyStatusExplanationLabel: UILabel!
    @IBOutlet private weak var confirmTrustwordsExplanationLabel: UILabel!
    @IBOutlet private weak var trustwordsContainer: UIView!

    // We manipulate constraints to support iPad orientations as this inherits from CustomTraitCollectionViewController,
    @IBOutlet private weak var containerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var distanceBetweenTitleAndContainerView: NSLayoutConstraint!
    @IBOutlet weak var secureCenterX: NSLayoutConstraint!
    @IBOutlet weak var distanceBetweenLabels: NSLayoutConstraint!

    
    public override func configureView() {
        setupHandshakeTitle()
        setupPrivacyStatusExplanationLabel()
        setupcCnfirmTrustwordsExplanationLabel()
        setupButtons()
        setupTrustwordsContainer()
        setupTrustwordsLabel()
        secureLabel.font = font
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        adjustConstraintsIfNeeded()
    }
}


// MARK: - Private - Setup View

extension TutorialStep2ViewController {

    private func setupTrustwordsLabel() {
        truswordsLabel.font = smallFont
        truswordsLabel.text = NSLocalizedString("OUTDISTANCE   CORRINA   ETHIOPIA    OUTDRAW   FLEECER", comment: "Some trustwords")
    }
    
    private func setupHandshakeTitle() {
        handshakeTitle.font = titleFont
        handshakeTitle.text = NSLocalizedString("Handshake", comment: "Title of the view")
    }

    private func setupPrivacyStatusExplanationLabel() {
        privacyStatusExplanationLabel.font = font
        privacyStatusExplanationLabel.text = NSLocalizedString("When you click on the Privacy Status icon in the top bar, you will get to Handshake, where you can verify your communication parner.", comment: "Privacy status explanation Label")
    }

    private func setupcCnfirmTrustwordsExplanationLabel() {
        confirmTrustwordsExplanationLabel.font = font
        confirmTrustwordsExplanationLabel.text = NSLocalizedString("When you confirm that the Trustwords of your communication partner are correct, your communication will be completely Secure & Trusted.", comment: "Confirm Trustwords explanation Label")
    }
    
    private func setupButtons() {
        //Confirm Button
        let confirmTitle = NSLocalizedString("Confirm", comment: "Confirm correct trustwords/PGP fingerprint")
        confirmButton.setTitle(confirmTitle, for: .normal)
        confirmButton.pEpIfyForTrust(backgroundColor: .pEpGreen, textColor: .white, insetPlusHorizontal: 10, insetPlusVertical : 5, cornerRadius : 4)
        confirmButton.isUserInteractionEnabled = false
        
        //Decline Button
        let declineTitle = NSLocalizedString("Decline", comment: "Incorrect trustwords/PGP fingerprint")
        declineButton.setTitle(declineTitle, for: .normal)
        declineButton.pEpIfyForTrust(backgroundColor: .pEpRed, textColor: .white, insetPlusHorizontal: 10, insetPlusVertical : 5, cornerRadius : 4)
        declineButton.isUserInteractionEnabled = false
    }

    private func setupTrustwordsContainer() {
        trustwordsContainer.layer.borderWidth = 1
        trustwordsContainer.layer.borderColor = UIColor.pEpGrayBorder.withAlphaComponent(0.5).cgColor
    }
}

// MARK: - Private - Adjust constraints

extension TutorialStep2ViewController {

    func adjustConstraintsIfNeeded() {
        guard let superView = view.superview, UIDevice.isIpad else {
            Log.shared.info("Superview is missing or is not needed to adjust constraints here")
            return
        }
        containerLeadingConstraint.constant = UIDevice.isLandscape ? Constants.Landscape.containerLeading : Constants.Portrait.containerLeading
        distanceBetweenLabels.constant = 50
        secureCenterX.constant = -6
        superView.layoutIfNeeded()
    }
    
    private struct Constants {
        struct Portrait {
            static let containerLeading: CGFloat = 50
            static let distanceBelowTitle: CGFloat = 20
        }

        struct Landscape {
            static let containerLeading: CGFloat = 100
            static let distanceBelowTitle: CGFloat = 40
        }
    }
}
