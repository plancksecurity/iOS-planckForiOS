//
//  UIUtils+KeySyncWizard.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox
import MessageModel

// MARK: - UIUtils+KeySyncWizard

extension UIUtils {

    private static var presenter: UIViewController {
        guard let visibleViewController = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No visible VC")
            return UIViewController()
        }
        return visibleViewController
    }
    
    private static var canPresent: Bool {
        let presenter = self.presenter // Avoid repeating the search of the presenter.
        if let wizardController = presenter.navigationController, wizardController.child(ofType: PEPAlertViewController.self) != nil {
            /// Valid case: there is a PEPAlerView already presented.
            return false
        }
        guard !(presenter is KeySyncWizardViewController) else {
            /// Valid case: there is a KeySyncWizard already presented.
            return false
        }
        return true
    }


    @discardableResult
    static public func presentKeySyncWizard(meFPR: String,
                                            partnerFPR: String,
                                            isNewGroup: Bool,
                                            completion: @escaping (KeySyncWizardViewController.Action) -> Void ) -> KeySyncWizardViewController? {
        guard let pEpSyncWizard = KeySyncWizardViewController.fromStoryboard(meFPR: meFPR,
                                                                             partnerFPR: partnerFPR,
                                                                             isNewGroup: isNewGroup,
                                                                             completion: completion) else {
            Log.shared.errorAndCrash("Missing pEpSyncWizard")
            return nil
        }
        return present(pEpSyncWizard)
    }

    private static func present(_ wizard: KeySyncWizardViewController) -> KeySyncWizardViewController? {
        guard canPresent else {
            return nil
        }
        DispatchQueue.main.async {
            presenter.present(wizard, animated: true, completion: nil)
        }
        return wizard
    }
    
    public static func presentKeySyncErrorView(isNewGroup: Bool, error: Error?, completion: ((KeySyncErrorResponse) -> ())? = nil) {
        guard canPresent else {
            return
        }
        guard let view =
                KeySyncErrorView.keySyncErrorView(viewController: presenter,
                                                  isNewGroup: isNewGroup,
                                                  error: error,
                                                  completion: completion) else {
            return
        }
        UIUtils.present(view)
    }
    
    public static func present(_ keySyncErrorView: PEPAlertViewController) {
        guard canPresent else {
            return
        }
        if let presentedViewController = presenter.presentedViewController {
            presentedViewController.dismiss(animated: true) {
                presenter.present(keySyncErrorView, animated: true)
            }
        } else {
            presenter.present(keySyncErrorView, animated: true)
        }
    }
}

