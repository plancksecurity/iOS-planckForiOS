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
    ///
    /// - Parameters:
    ///   - meFPR: The fingerprints of the user.
    ///   - partnerFPR: The fingerprints of his communication partner.
    ///   - isNewGroup: Indicates if it's a new group or it's joining an existing group
    ///   - completion: Callback to be executed when the user interacts with keysync wizard buttons.
    /// - Returns: the view controller of the key sync, if it's presented, nil otherwise.
    @discardableResult
    static public func showKeySyncWizard(meFPR: String,
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
        UIUtils.present(keySyncErrorView)
    }
}

// MARK: - Private

extension UIUtils {

    /// Present an alert view if possible.
    /// - Parameter keySyncErrorViewController: The view controller to present.
    private static func present(_ keySyncErrorViewController: PEPAlertViewController) {
        guard let presenter = UIApplication.currentlyVisibleViewController() else {
            Log.shared.error("Presenter is gone")
            return
        }
        /// If there is an error already
        if let presentedViewController = presenter.presentedViewController {
            presentedViewController.dismiss(animated: true) {
                UIUtils.present(keySyncErrorViewController)
            }
            return
        }
        /// If there is a Keysync presented.
        if presenter is KeySyncWizardViewController {
            presenter.dismiss(animated: true) {
                let newPresenter = UIApplication.currentlyVisibleViewController()
                newPresenter?.present(keySyncErrorViewController, animated: true, completion: nil)
            }
            return
        }
        presenter.present(keySyncErrorViewController, animated: true, completion: nil)
    }

    /// Present the keysync wizard if possible.
    /// - Parameter wizardViewController: The wizard view controller
    /// - Returns: The presented wizard View controller . Nil if it wasn't presented.
    private static func present(_ wizardViewController: KeySyncWizardViewController) -> KeySyncWizardViewController? {
        guard let presenter = UIApplication.currentlyVisibleViewController() else {
            Log.shared.error("Presenter is gone")
            return nil
        }
        if canPresentWizard(presenter: presenter) {
            DispatchQueue.main.async {
                presenter.present(wizardViewController, animated: true, completion: nil)
            }
            return wizardViewController
        }
        return nil
    }

    private static func canPresentWizard(presenter: UIViewController) -> Bool {
        if let wizardPresenter = presenter.navigationController, wizardPresenter.child(ofType: PEPAlertViewController.self) != nil {
            /// Valid case: there is a PEPAlerView already presented.
            return false
        }
        guard !(presenter is KeySyncWizardViewController) else {
            /// Valid case: there is a KeySyncWizard already presented.
            return false
        }
        return true
    }
}
