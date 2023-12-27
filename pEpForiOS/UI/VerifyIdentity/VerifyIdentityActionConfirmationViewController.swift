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

enum Action {
    case accept
    case reject
}

class VerifyIdentityActionConfirmationViewController: UIViewController {

    public var viewModel: VerifyIdentityViewModel?
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
        guard let vm = viewModel else {
            return
        }
        handleUserInput(action: vm.action)
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
        dismiss(animated: true, completion: {
            UIApplication.currentlyVisibleViewController().navigationController?.popViewController(animated: true)
        })
    }
    
    func showResetPartnerKeySuccessfully() {
        // TODO: implement me!
        print("")
    }
    
    func showResetPartnerKeyFailed(forRowAt indexPath: IndexPath) {
        // TODO: implement me!
        print("")
    }
}

// MARK: - Private

extension VerifyIdentityActionConfirmationViewController {
    
    private func setStaticTexts() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        guard let name = trustManagementViewModel?.rows.first?.partnerTitle else {
            return
        }
        messageLabel.text = vm.getVerificationMessage(partner: name)
        actionButton.setPEPFont(style: .body, weight: .regular)
        actionButton.setTitleColor(vm.action == .accept ? UIColor.pEpGreen : UIColor.pEpRed, for: [.normal])
        actionButton.setTitle(vm.confirmButtonTitle, for: [.normal])
        cancelButton.setPEPFont(style: .body, weight: .regular)
        cancelButton.setTitleColor(UIColor.pEpRed, for: [.normal])
        cancelButton.setTitle(vm.closeButtonTitle, for: [.normal])
    }
    
    private func handleUserInput(action: Action) {
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
