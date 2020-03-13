//
//  PEPSyncHandshakeService+UIUtils.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

// MARK: - PEPSyncHandshakeService+UIUtils

extension KeySyncHandshakeService {
    @discardableResult
    func presentKeySyncWizard(meFPR: String,
                              partnerFPR: String,
                              isNewGroup: Bool,
                              completion: @escaping (KeySyncWizardViewController.Action) -> Void )
        -> KeySyncWizardViewController? {
            guard let pEpSyncWizard = KeySyncWizardViewController.fromStoryboard(meFPR: meFPR,
                                                                                      partnerFPR: partnerFPR,
                                                                                      isNewGroup: isNewGroup,
                                                                                      completion: completion) else {
                                                                                        return nil
            }
            DispatchQueue.main.async { [weak self] in
                pEpSyncWizard.modalPresentationStyle = .overFullScreen
                guard let visibleViewController = UIApplication.currentlyVisibleViewController() else {
                    Log.shared.errorAndCrash("No visible VC")
                    return
                }
                visibleViewController.present(pEpSyncWizard, animated: true, completion: nil)
            }
            return pEpSyncWizard
    }
}
