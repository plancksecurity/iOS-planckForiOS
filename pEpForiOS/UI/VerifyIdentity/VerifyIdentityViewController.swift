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
    
    var languages: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStaticTexts()
        let tap = UITapGestureRecognizer(target: self, action: #selector(toogle))
        trustwordsLabel.isUserInteractionEnabled = true
        trustwordsLabel.addGestureRecognizer(tap)

    }
    
    @objc func toogle() {
        guard let vm = trustManagementViewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleToggleLongTrustwords(forRowAt: IndexPath(row: 0, section: 0))
    }

    @IBAction func closeButtonPressed() {
        dismiss(animated: true)
    }

    @IBAction func trustwordsLanguageButtonPressed() {
        let alertController = UIUtils.actionSheet()
        guard let vm = trustManagementViewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        //For every language a row in the action sheet.
        vm.languages { [weak self] langs in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            for language in langs {
                guard let languageName = NSLocale.current.localizedString(forLanguageCode: language)?.capitalized
                else {
                    Log.shared.debug("Language name not found")
                    break
                }
                let action = UIAlertAction(title: languageName, style: .default) { (action) in
                    vm.handleDidSelect(language: language, forRowAt: IndexPath(row: 0, section: 0))
                }
                alertController.addAction(action)
            }
            
            //For the cancel button another action.
            let cancel = NSLocalizedString("Cancel", comment: "VerifyIdentityView: trustword language selector cancel button label")
            let cancelAction = UIAlertAction(title: cancel, style: .cancel) { _ in
                alertController.dismiss(animated: true, completion: nil)
            }
            cancelAction.accessibilityIdentifier = AccessibilityIdentifier.cancelButton
            alertController.addAction(cancelAction)
            //Ipad behavior.
            //alertController.popoverPresentationController?.sourceView = languageButton
            //alertController.popoverPresentationController?.sourceRect = languageButton.bounds
            me.present(alertController, animated: true, completion: nil)
        }
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

extension VerifyIdentityViewController: TrustManagementViewModelDelegate {
    func reload() {
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

    func dataChanged(forRowAt indexPath: IndexPath) {
        reload()
    }

    func showResetPartnerKeySuccessfully() { }

    func showResetPartnerKeyFailed(forRowAt indexPath: IndexPath) { }
}
