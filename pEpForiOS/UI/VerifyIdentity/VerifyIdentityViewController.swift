//
//  VerifyIdentityViewController.swift
//  planckForiOS
//
//  Created by Martin Brude on 13/12/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import UIKit
import PlanckToolbox

class VerifyIdentityViewController: UIViewController {

    private let viewModel = VerifyIdentityViewModel()

    static let storyboardId = "VerifyIdentityViewController"

    @IBOutlet private weak var verifyIdentityTitleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var trustwordsTitleLabel: UILabel!
    @IBOutlet private weak var trustwordsLabel: UILabel!
    @IBOutlet private weak var ownDeviceFingerprintsLabel: UILabel!
    @IBOutlet private weak var ownDeviceUsernameLabel: UILabel!
    @IBOutlet private weak var otherDeviceFingerprints: UILabel!
    @IBOutlet private weak var otherDeviceUsernameLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStaticTexts()
    }
    
    @IBAction func closeButtonPressed() {
        dismiss(animated: true)
    }

    @IBAction func trustwordsLanguageButtonPressed() {
        
    }
}

extension VerifyIdentityViewController {
    private func setStaticTexts() {
        verifyIdentityTitleLabel.text = viewModel.title
        messageLabel.text = viewModel.message
        trustwordsTitleLabel.text = viewModel.trustwordsTitle
        closeButton.setPEPFont(style: .body, weight: .regular)
        closeButton.setTitleColor(UIColor.planckLightPurpleText, for: [.normal])
        closeButton.setTitle(viewModel.closeButtonTitle, for: [.normal])
    }
}
