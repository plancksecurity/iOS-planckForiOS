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
        return show(pEpSyncWizard)
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
        UIUtils.show(keySyncErrorView)
    }
}

// MARK: - Private

extension UIUtils {

    /// Present an alert view if possible.
    /// - Parameter keySyncErrorViewController: The view controller to present.
    @discardableResult
    private static func show(_ keySyncErrorViewController: PEPAlertViewController) -> PEPAlertViewController? {
        return UIUtils.show(keySyncErrorViewController, ofType: PEPAlertViewController.self)
    }

    /// Present the keysync wizard if possible.
    /// - Parameter wizardViewController: The wizard view controller
    /// - Returns: The presented wizard View controller . Nil if it wasn't presented.
    @discardableResult
    private static func show(_ wizardViewController: KeySyncWizardViewController) -> KeySyncWizardViewController? {
        return UIUtils.show(wizardViewController, ofType: KeySyncWizardViewController.self)
    }

    @discardableResult
    private static func show<T: UIViewController>(_ viewController: T, ofType type: T.Type) -> T? {
        // If the presenter is an alert view
        // - Do not show another alert view.
        // - Only dismiss and present a KeySync wizard if needed.
        //
        // If the presenter is a KeySync wizard, dismiss it and present whatever is received.
        // If the presenter is not an alert view nor a KeySync wizard, just present whatever is received.
        let presenter = UIApplication.currentlyVisibleViewController()
        if presenter is PEPAlertViewController {
            if viewController is PEPAlertViewController {
                return nil
            } else if viewController is KeySyncWizardViewController {
                dismissAndpresent(viewController: viewController, withPresenter: presenter)
                return viewController
            }
        } else if presenter is KeySyncWizardViewController {
            dismissAndpresent(viewController: viewController, withPresenter: presenter)
            return viewController
        } else {
            DispatchQueue.main.async {
                presenter.present(viewController, animated: true)
            }
            return viewController
        }
        return nil
    }

    private static func dismissAndpresent(viewController: UIViewController, withPresenter presenter: UIViewController) {
        DispatchQueue.main.async {
            presenter.dismiss(animated: true) {
                let newPresenter = UIApplication.currentlyVisibleViewController()
                newPresenter.present(viewController, animated: true)
            }
        }
    }
}



