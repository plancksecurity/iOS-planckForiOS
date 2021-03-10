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

    /// Presents the KeySync wizard, if possible.
    /// - note: This is an async task. The `KeySyncWizardViewController` is NOT presented yet after this method returned!
    /// - Parameters:
    ///   - meFPR: The fingerprints of the user.
    ///   - partnerFPR: The fingerprints of his communication partner.
    ///   - isNewGroup: Indicates if it's a new group or it's joining an existing group
    ///   - wizardCallback: Callback to be executed when the user interacts with keysync wizard buttons.
    ///   - presentationCallback: Callback to executed when the presentation is done.
    static public func showKeySyncWizard(meFPR: String, partnerFPR: String, isNewGroup: Bool,
                                         wizardCallback: @escaping (KeySyncWizardViewController.Action) -> Void,
                                         presentationCallback: @escaping (UIViewController?)->()) {
        guard let pEpSyncWizard = KeySyncWizardViewController.fromStoryboard(meFPR: meFPR,
                                                                             partnerFPR: partnerFPR,
                                                                             isNewGroup: isNewGroup,
                                                                             completion: wizardCallback) else {
            Log.shared.errorAndCrash("Missing pEpSyncWizard")
            return
        }
        show(pEpSyncWizard, presentationCallback: presentationCallback)
    }

    /// Present the alert views, if possible
    /// - Parameters:
    ///   - isNewGroup: Indicates if it's a new group or it's joining an existing group
    ///   - error: The key sync error
    ///   - completion: The callback to be executed when the user interacts with the error alert view buttons.
    public static func showKeySyncErrorView(isNewGroup: Bool, error: Error?, completion: ((KeySyncErrorResponse) -> ())? = nil) {
        let keySyncErrorViewController = PEPAlertViewController.getKeySyncErrorViewController(isNewGroup: isNewGroup) { (action) in
            switch action {
            case .tryAgain:
                completion?(.tryAgain)
            case .notNow:
                completion?(.notNow)
            }
        }
        guard let keySyncErrorView = keySyncErrorViewController else {
            Log.shared.errorAndCrash("KeySyncErrorView cant be instanciated")
            return
        }
        DispatchQueue.main.async {
            UIUtils.show(keySyncErrorView)
        }
    }
}

// MARK: - Private

extension UIUtils {

    /// Shows a View Controller, probably a KeySync Wizard or a KeySync error
    ///
    /// - Parameter viewControllerToPresent: The ViewController to present
    /// - Returns: The viewControllerToPresent, nil if was not presented.
    /// Will happen if the presenter is a KeySync error and the view controller to present is also a KeySync error.
    private static func show<T: UIViewController>(_ viewControllerToPresent: T,
                                                   presentationCallback: ((T?)->())? = nil) {
        DispatchQueue.main.async {
            var vcToPresent: T? = viewControllerToPresent
            let currentlyShownViewController = UIApplication.currentlyVisibleViewController()

            // If the presenter is an pEp Sync Error alert view
            //  - Do not show another pEp Sync Error alert view.
            //  - Dismiss and present a KeySync wizard if needed.
            //
            if currentlyShownViewController is PEPAlertViewController {
                if viewControllerToPresent is PEPAlertViewController {
                    vcToPresent = nil
                } else if viewControllerToPresent is KeySyncWizardViewController {
                    dismissCurrentlyVisibleViewController(andPresent: viewControllerToPresent)
                    vcToPresent = viewControllerToPresent
                }
                // If the presenter is a KeySync wizard
                //  - Dismiss it and present whatever is received.
                //
            } else if currentlyShownViewController is KeySyncWizardViewController {
                dismissCurrentlyVisibleViewController(andPresent: viewControllerToPresent)
                vcToPresent = viewControllerToPresent
            }
            // If the presenter is not an alert view nor a KeySync wizard, just present whatever is received.
            if let vc = vcToPresent {
                currentlyShownViewController.present(vc, animated: true)
            }
            presentationCallback?(vcToPresent)
        }
    }

    private static func dismissCurrentlyVisibleViewController(andPresent viewController: UIViewController) {
        DispatchQueue.main.async {
            let currentlyShownViewController = UIApplication.currentlyVisibleViewController()
            currentlyShownViewController.dismiss(animated: true) {
                let newCurrentlyShownViewController = UIApplication.currentlyVisibleViewController()
                newCurrentlyShownViewController.present(viewController, animated: true)
            }
        }
    }
}
