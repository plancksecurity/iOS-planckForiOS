//
//  UIUtils+KeySyncWizard.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

// MARK: - UIUtils+KeySyncWizard

extension UIUtils {

    private static var wizardPresenter: UIViewController {
        guard let visibleViewController = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No visible VC")
            return UIViewController()
        }
        return visibleViewController
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
        /// Guard if the presenter isn't already a wizard
        guard !(wizardPresenter is KeySyncWizardViewController) else {
            /// Valid case: there is a KeySyncWizard already presented.
            return nil
        }
        DispatchQueue.main.async {
            wizardPresenter.present(wizard, animated: true, completion: nil)
        }
        return wizard
    }
}

