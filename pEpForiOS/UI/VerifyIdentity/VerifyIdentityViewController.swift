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
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    // Static content
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var trustwordsTitleLabel: UILabel!
    
    //Buttons
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var rejectButton: UIButton!
    
    // Dynamic content
    @IBOutlet private weak var trustwordsLabel: UILabel!
    @IBOutlet private weak var ownDeviceFingerprintsLabel: UILabel!
    @IBOutlet private weak var ownDeviceUsernameLabel: UILabel!
    @IBOutlet private weak var otherDeviceFingerprintsLabel: UILabel!
    @IBOutlet private weak var otherDeviceUsernameLabel: UILabel!

    // TrustManagementViewModel generates rows and uses the indexPath of the tableview.
    // Here we don't have any table view. We show only the trustwords of only one row.
    private let indexPath = IndexPath(row: 0, section: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Verify Identity", comment: "Verify Identity")
        setStaticTexts()
        let tap = UITapGestureRecognizer(target: self, action: #selector(toogleTrustwordsLength))
        trustwordsLabel.isUserInteractionEnabled = true
        trustwordsLabel.addGestureRecognizer(tap)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        confirmButton.isHidden = !vm.shouldManageTrust
        rejectButton.isHidden = !vm.shouldManageTrust
    }
    
    @IBAction func confirmButtonPressed() {
        show(action: VerificationAction.accept)
    }

    @IBAction func rejectButtonPressed() {
        show(action: VerificationAction.reject)
    }

    func show(action: VerificationAction) {
        let storyboard = UIStoryboard(name: Constants.reusableStoryboard, bundle: .main)
        guard let vc = storyboard.instantiateViewController(
            withIdentifier: VerifyIdentityActionConfirmationViewController.storyboardId) as? VerifyIdentityActionConfirmationViewController else {
                Log.shared.errorAndCrash("Fail to instantiateViewController VerifyIdentityActionConfirmationViewController")
                return
        }
        viewModel?.action = action
        vc.viewModel = viewModel
        trustManagementViewModel?.delegate = vc
        vc.trustManagementViewModel = trustManagementViewModel
        UIUtils.showVerifyIdentityConfirmation(viewContorller: vc)
    }

    @objc func toogleTrustwordsLength() {
        guard let vm = trustManagementViewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleToggleLongTrustwords(forRowAt: indexPath)
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
                    vm.handleDidSelect(language: language, forRowAt: me.indexPath)
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
            alertController.popoverPresentationController?.sourceView = me.trustwordsLabel
            alertController.popoverPresentationController?.sourceRect = me.trustwordsLabel.bounds
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
        
        messageLabel.text = vm.messageText
        trustwordsTitleLabel.text = vm.trustwordsTitle
        
        confirmButton.setPEPFont(style: .body, weight: .regular)
        confirmButton.setTitleColor(UIColor.pEpGreen, for: [.normal])
        confirmButton.setTitle(vm.confirmButtonTitle, for: [.normal])
        
        rejectButton.setPEPFont(style: .body, weight: .regular)
        rejectButton.setTitleColor(UIColor.pEpRed, for: [.normal])
        rejectButton.setTitle(vm.rejectButtonTitle, for: [.normal])
    }
}

extension VerifyIdentityViewController: TrustManagementViewModelDelegate {
    func reload() {
        guard viewIfLoaded != nil else {
            return
        }
        guard let vm = trustManagementViewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        guard let row = vm.rows.first else {
            Log.shared.errorAndCrash("Rows not found")
            return
        }
        let trustwords = row.trustwords ?? NSLocalizedString("Trustwords Not Available", comment: "")
        let trustwordsHeight: CGFloat = trustwords.height(withConstrainedWidth: trustwordsLabel.frame.width, font: trustwordsLabel.font)
        let defaultContainerHeightWithoutTrustwords = 300.0
        var heightToSet = defaultContainerHeightWithoutTrustwords + trustwordsHeight

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) { [weak self] in
            guard let me = self else { return }
            me.containerHeightConstraint.constant = CGFloat(heightToSet)
        } completion: { _ in
            let fingerprintNotAvailable = NSLocalizedString("Fingerprint Not Available", comment: "Fingerprint Not Available")
            self.trustwordsLabel.text = trustwords
            self.ownDeviceFingerprintsLabel.text = row.ownFormattedFingerprint ?? fingerprintNotAvailable
            self.ownDeviceUsernameLabel.text = row.ownTitle
            self.otherDeviceFingerprintsLabel.text = row.partnerFormattedFingerprint ?? fingerprintNotAvailable
            self.otherDeviceUsernameLabel.text = row.partnerTitle
        }
    }

    func dataChanged(forRowAt indexPath: IndexPath) {
        reload()
    }

    func showResetPartnerKeySuccessfully() { }

    func showResetPartnerKeyFailed(forRowAt indexPath: IndexPath) { }
}
