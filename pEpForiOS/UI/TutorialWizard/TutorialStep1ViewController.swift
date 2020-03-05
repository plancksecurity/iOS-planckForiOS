//
//  TutorialStep1ViewController.swift
//  pEp
//
//  Created by Martin Brude on 04/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class TutorialStep1ViewController: TutorialStepViewController {
    @IBOutlet private weak var secureLabel: UILabel!
    @IBOutlet private weak var secureDescriptionLabel: UILabel!
    @IBOutlet private weak var secureAndTrustedLabel: UILabel!
    @IBOutlet private weak var secureAndTrustDescription: UILabel!
    @IBOutlet private weak var mistrustedLabel: UILabel!
    @IBOutlet private weak var mistrustedDescription: UILabel!

    @IBOutlet private weak var secureContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var distanceBetweenSecureContainerAndSecureDescription: NSLayoutConstraint!
    @IBOutlet private weak var secureDescriptionToSecureAndTrust: NSLayoutConstraint!
    @IBOutlet private weak var distanceBetweenSecureAndTrustDescriptionAndMistrustedContainer: NSLayoutConstraint!
    @IBOutlet private weak var distanceBetweenSecureAndTrustContainerAndDescription: NSLayoutConstraint!
    @IBOutlet weak var distanceBetweenMistrustAndDescription: NSLayoutConstraint!
    
    @IBOutlet weak var secureDescriptionTrailing: NSLayoutConstraint!
    
    public override func configureView() {
        setupSecureLabel()
        setupSecureDescriptionLabel()
        setupSecureAndTrustedLabel()
        setupSecureAndTrustedDescriptionLabel()
        setupMistrustedLabel()
        setupMistrustedDescriptionLabel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustConstraintsIfNeeded()
    }
}

extension TutorialStep1ViewController {

    private func setupSecureLabel() {
        secureLabel.font = subtitleFont
        secureLabel.text = NSLocalizedString("Secure", comment: "Secure Label - Step 1")
    }

    private func setupSecureDescriptionLabel() {
        secureDescriptionLabel.text = NSLocalizedString("With this Privacy Status all communication is Secure, but to confirm that your contact is really the person you know, you should compare Trustwords with this contact.", comment: "Secure Description Label - Step 1")
        secureDescriptionLabel.font = font
    }

    private func setupSecureAndTrustedLabel() {
        secureAndTrustedLabel.font = subtitleFont
        secureAndTrustedLabel.text = NSLocalizedString("Secure & Trusted", comment: "Secure & Trusted Label - Step 1")
    }

    private func setupSecureAndTrustedDescriptionLabel() {
        secureAndTrustDescription.text = NSLocalizedString("When the Trustwords are confirmed to be correct and the Handshake is done, the communication will be completely secure and trusted", comment: "Secure & Trusted Description Label - Step 1")
        secureAndTrustDescription.font = font
    }

    private func setupMistrustedLabel() {
        mistrustedLabel.font = subtitleFont
        mistrustedLabel.text = NSLocalizedString("Mistrusted", comment: "Mistrusted - Step 1")
    }

    private func setupMistrustedDescriptionLabel() {
        mistrustedDescription.text = NSLocalizedString("If the Trustwords are not correct, there could be an attack by a man‑in‑the‑middle.", comment: "Secure & Trusted Description Label - Step 1")
        mistrustedDescription.font = font
    }
    
    func adjustConstraintsIfNeeded() {
        guard let superView = view.superview, isIpad else {
            Log.shared.error("Superview is missing or is not needed to adjust constraints here")
            return
        }
        secureContainerTopConstraint.constant = isLandscape ? Constants.Landscape.secureContainerTop :
        Constants.Portrait.secureContainerTop
        
        distanceBetweenSecureContainerAndSecureDescription.constant = isLandscape ? Constants.Landscape.containerAndDescriptionDistance :
        Constants.Portrait.containerAndDescriptionDistance

        secureDescriptionToSecureAndTrust.constant = isLandscape ? Constants.Landscape.containerAndDescriptionDistance :
        Constants.Portrait.containerAndDescriptionDistance

        distanceBetweenSecureAndTrustDescriptionAndMistrustedContainer.constant = isLandscape ? Constants.Landscape.containerAndDescriptionDistance :
        Constants.Portrait.containerAndDescriptionDistance

        distanceBetweenSecureAndTrustContainerAndDescription.constant = isLandscape ? Constants.Landscape.containerAndDescriptionDistance :
        Constants.Portrait.containerAndDescriptionDistance

        distanceBetweenMistrustAndDescription.constant = isLandscape ? Constants.Landscape.containerAndDescriptionDistance :
        Constants.Portrait.containerAndDescriptionDistance

        secureDescriptionTrailing.constant = isLandscape ? Constants.Landscape.descriptionTrailing :
        Constants.Portrait.descriptionTrailing
        
        superView.layoutIfNeeded()
    }
    
    private struct Constants {
        struct Portrait {
            static let secureContainerTop: CGFloat = 50.0
            static let containerAndDescriptionDistance: CGFloat = 40.0
            static let descriptionTrailing: CGFloat = 85.0
        }

        struct Landscape {
            static let secureContainerTop: CGFloat = 50.0
            static let containerAndDescriptionDistance: CGFloat = 35.0
            static let descriptionTrailing: CGFloat = 85.0
        }
    }
}
