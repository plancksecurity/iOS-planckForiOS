//
//  VerifyIdentityActionConfirmationViewController.swift
//  planckForiOS
//
//  Created by Martin Brude on 21/12/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

enum VerificationAction {
    case accept
    case reject
}

class VerifyIdentityActionConfirmationViewController: UIViewController {

    public var verifyIdentityViewModel: VerifyIdentityViewModel?
    public var trustManagementViewModel: TrustManagementViewModel?
    public static let storyboardId = "VerifyIdentityActionConfirmationViewController"

    // Static content
    @IBOutlet private weak var verifyIdentityTitleLabel: UIView!
    @IBOutlet private weak var messageLabel: UILabel!

    //Buttons
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    private let indexPath = IndexPath(row: 0, section: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Verify Identity", comment: "Verify Identity")
        setStaticTexts()
    }

    @IBAction func confirmationButtonPressed() {
        guard let action = verifyIdentityViewModel?.action else {
            Log.shared.errorAndCrash("No VM or No decision")
            return
        }
        handleUserInput(action: action)
    }

    @IBAction func closeButtonPressed() {
        dismiss(animated: true)
    }
}

extension VerifyIdentityActionConfirmationViewController: TrustManagementViewModelDelegate {
    func reload() { }
    
    func dataChanged(forRowAt indexPath: IndexPath) {
        guard indexPath == self.indexPath else {
            Log.shared.errorAndCrash("Extremely unexpected")
            return
        }
        guard let vm = verifyIdentityViewModel, 
                let trustVM = trustManagementViewModel,
              let name = trustVM.rows.first?.partnerTitle else {
            Log.shared.errorAndCrash("Trustwords not found")
            return
        }
        let title = vm.title
        let message = vm.getVerificationResultMessage(partner: name)
        
        dismiss(animated: true, completion: {
            UIApplication.currentlyVisibleViewController().navigationController?.popViewController(animated: true, completion: {
                UIUtils.showAlertWithOnlyCloseButton(title: title, message: message)
            })
        })
    }
    
    func showResetPartnerKeySuccessfully() { }
    
    func showResetPartnerKeyFailed(forRowAt indexPath: IndexPath) { }
}

// MARK: - Private

extension VerifyIdentityActionConfirmationViewController {
    
    private func setStaticTexts() {
        guard let vm = verifyIdentityViewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        guard let name = trustManagementViewModel?.rows.first?.partnerTitle else {
            return
        }
        messageLabel.text = vm.getVerificationMessage(partner: name)
        actionButton.setPEPFont(style: .body, weight: .regular)
        actionButton.setTitleColor(vm.action == .accept ? UIColor.pEpGreen : UIColor.pEpRed, for: [.normal])
        actionButton.setTitle(vm.action == .accept ? vm.reconfirmButtonTitle : vm.confirmRejectionButtonTitle, for: [.normal])
        cancelButton.setPEPFont(style: .body, weight: .regular)
        cancelButton.setTitleColor(UIColor.planckLightPurpleText, for: [.normal])
        cancelButton.setTitle(vm.cancelButtonTitle, for: [.normal])
    }
    
    private func handleUserInput(action: VerificationAction) {
        guard let vm = trustManagementViewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        if action == .accept {
            vm.handleConfirmHandshakePressed(at: indexPath)
        } else if action == .reject {
            vm.handleRejectHandshakePressed(at: indexPath)
        }
    }
}
