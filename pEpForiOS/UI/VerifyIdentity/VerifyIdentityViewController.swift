//
//  VerifyIdentityViewController.swift
//  planckForiOS
//
//  Created by Martin Brude on 13/12/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

class VerifyIdentityViewController: UIViewController {

    public var viewModel: VerifyIdentityViewModel?
    public var trustManagementViewModel: TrustManagementViewModel?
    public static let storyboardId = "VerifyIdentityViewController"

    // Static
    @IBOutlet private weak var verifyIdentityTitleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var trustwordsTitleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!

    // Dynamic
    @IBOutlet private weak var trustwordsLabel: UILabel!
    @IBOutlet private weak var ownDeviceFingerprintsLabel: UILabel!
    @IBOutlet private weak var ownDeviceUsernameLabel: UILabel!
    @IBOutlet private weak var otherDeviceFingerprints: UILabel!
    @IBOutlet private weak var otherDeviceUsernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStaticTexts()
        updateUI()
    }
    
    func updateUI() {
        guard let vm = trustManagementViewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        guard let row = vm.rows.first else {
            Log.shared.errorAndCrash("Row not found")
            return
        }
        trustwordsLabel.text = row.trustwords
        ownDeviceFingerprintsLabel.text = row.ownFormattedFingerprint
        ownDeviceUsernameLabel.text = row.ownTitle
        otherDeviceFingerprints.text = row.partnerFormattedFingerprint
        otherDeviceUsernameLabel.text = row.partnerTitle
    }
    
    @IBAction func closeButtonPressed() {
        dismiss(animated: true)
    }

    @IBAction func trustwordsLanguageButtonPressed() {
        
    }
}

// MARK: - Private

extension VerifyIdentityViewController {
    
    private func setStaticTexts() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        
        verifyIdentityTitleLabel.text = vm.title
        messageLabel.text = vm.messageText
        trustwordsTitleLabel.text = vm.trustwordsTitle
        closeButton.setPEPFont(style: .body, weight: .regular)
        closeButton.setTitleColor(UIColor.planckLightPurpleText, for: [.normal])
        closeButton.setTitle(vm.closeButtonTitle, for: [.normal])
    }
}
