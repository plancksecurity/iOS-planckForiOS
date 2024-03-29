//
//  UIUtils+KeySyncWizard.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import PlanckToolbox
import MessageModel

// MARK: - UIUtils+KeySyncWizard

extension UIUtils {

    /// Presents the KeySync wizard, if possible.
    /// - note: This is an async task. The `KeySyncWizardViewController` is NOT presented yet after this method returned!
    /// - Parameters:
    ///   - keySyncHandshakeData: All data needed for a key sync handshake
    ///   - completion: Callback to be executed when the user interacts with keysync wizard buttons.
    /// - Returns: the view controller of the key sync, if it's presented, nil otherwise.
    @discardableResult
    static public func showKeySyncWizard(keySyncHandshakeData: KeySyncHandshakeData,
                                         completion: @escaping (KeySyncWizardViewController.Action) -> Void ) -> KeySyncWizardViewController? {
        guard let pEpSyncWizard = KeySyncWizardViewController.fromStoryboard(keySyncHandshakeData: keySyncHandshakeData,
                                                                             completion: completion) else {
            Log.shared.errorAndCrash("Missing pEpSyncWizard")
            return nil
        }
        AppSettings.shared.keySyncWizardWasShown = true
        return show(pEpSyncWizard)
    }

    /// Present the alert views, if possible
    /// - Parameters:
    ///   - isNewGroup: Indicates if it's a new group or it's joining an existing group
    ///   - error: The key sync error
    ///   - completion: The callback to be executed when the user interacts with the error alert view buttons.
    public static func showKeySyncErrorView(isNewGroup: Bool, error: Error?, completion: ((KeySyncErrorResponse) -> ())? = nil) {
        DispatchQueue.main.async {
            let keySyncErrorViewController = PlanckAlertViewController.getKeySyncErrorViewController(isNewGroup: isNewGroup) { (action) in
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
            UIUtils.show(keySyncErrorView)
        }
    }
}

// MARK: - Verify Identity

extension UIUtils {
    static public func showVerifyIdentityConfirmationOK() {
    }
    
    static public func showVerifyIdentityRejectionOK() {
        
    }

    static public func showVerifyIdentityConfirmation(viewContorller: VerifyIdentityActionConfirmationViewController) {
        DispatchQueue.main.async {
            viewContorller.modalPresentationStyle = .overFullScreen
            show(viewContorller)
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
    @discardableResult
    private static func show<T: UIViewController>(_ viewControllerToPresent: T) -> T? {
        let currentlyShownViewController = UIApplication.currentlyVisibleViewController()

        // If the presenter is an pEp Sync Error alert view
        //  - Do not show another pEp Sync Error alert view.
        //  - Dismiss and present a KeySync wizard if needed.
        //
        if currentlyShownViewController is PlanckAlertViewController {
            if viewControllerToPresent is PlanckAlertViewController {
                return nil
            } else if viewControllerToPresent is KeySyncWizardViewController {
                dismissCurrentlyVisibleViewController(andPresent: viewControllerToPresent)
                return viewControllerToPresent
            }
            // If the presenter is a KeySync wizard
            //  - Dismiss it and present whatever is received.
            //
        } else if currentlyShownViewController is KeySyncWizardViewController {
            dismissCurrentlyVisibleViewController(andPresent: viewControllerToPresent)
            return viewControllerToPresent
        }
        // If the presenter is not an alert view nor a KeySync wizard, just present whatever is received.
        DispatchQueue.main.async {
            currentlyShownViewController.present(viewControllerToPresent, animated: true)
        }
        return viewControllerToPresent
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
