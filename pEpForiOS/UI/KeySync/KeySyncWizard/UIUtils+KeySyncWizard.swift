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

    /// Present the alert views, if possible
    /// - Parameters:
    ///   - isNewGroup: Indicates if it's a new group or it's joining an existing group
    ///   - error: The key sync error
    ///   - completion: The callback to be executed when the user interacts with the error alert view buttons.
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
}

// MARK: - Private

extension UIUtils {

    /// The presenter for keysync views: the wizard or error alert views.
    private static var presenter: UIViewController {
        guard let visibleViewController = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No visible VC")
            return UIViewController()
        }
        return visibleViewController
    }

    /// Evaluates if it's possible to present a view for keysync.
    /// That means: there is not other KeySyncWizard or PEPAlerView already presented.
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

    /// Present an alert view if possible.
    /// - Parameter keySyncErrorViewController: The view controller to present.
    private static func present(_ keySyncErrorViewController: PEPAlertViewController) {
        guard canPresent else {
            return
        }
        if let presentedViewController = presenter.presentedViewController {
            presentedViewController.dismiss(animated: true) {
                presenter.present(keySyncErrorViewController, animated: true)
            }
        } else {
            presenter.present(keySyncErrorViewController, animated: true)
        }
    }

    /// Present the keysync wizard if possible.
    /// - Parameter wizardViewController: The wizard view controller
    /// - Returns: The presented wizard View controller . Nil if it wasn't presented.
    private static func present(_ wizardViewController: KeySyncWizardViewController) -> KeySyncWizardViewController? {
        guard canPresent else {
            return nil
        }
        DispatchQueue.main.async {
            presenter.present(wizardViewController, animated: true, completion: nil)
        }
        return wizardViewController
    }
}
