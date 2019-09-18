//
//  KeySyncHandshakeService.swift
//  pEp
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

class KeySyncHandshakeService {
    weak var presenter: UIViewController?
    
    private var alertView: UIAlertController? = nil
}

extension KeySyncHandshakeService: KeySyncServiceHandshakeDelegate {
    
    func showHandshake(me: PEPIdentity,
                       partner: PEPIdentity,
                       isNewGroup: Bool,
                       completion: ((PEPSyncHandshakeResult)->())? = nil) {

        guard let viewController = presenter else {
            Log.shared.errorAndCrash("No Presenter")
            return
        }
        guard let meFPR = me.fingerPrint, let partnerFPR = partner.fingerPrint else {
            Log.shared.errorAndCrash("Missing FPRs")
            return
        }

        viewController.presentKeySyncWizard(meFPR: meFPR,
                                            partnerFPR: partnerFPR,
                                            isNewGroup: isNewGroup) { action in
                                                switch action {
                                                case .accept:
                                                    completion?(.accepted)
                                                case .cancel:
                                                    completion?(.cancel)
                                                case .decline:
                                                    completion?(.rejected)
                                                }
        }
    }
    
    //!!!: unimplemented stub
    func showCurrentlyGroupingDevices() {
        // When implementing IOS-1712, show the additional (animated) view here.
        Log.shared.warn("Unimplemented stub. \n\n################################\n################################\nshowCurrentlyGroupingDevices called")
    }
    
    func cancelHandshake() {
        guard let keySyncWizard = presenter?.presentedViewController as? PEPPageViewController else {
            return
        }
        keySyncWizard.dismiss()
    }
    
    func showSuccessfullyGrouped() {
        guard let keySyncWizard = presenter?.presentedViewController as? PEPPageViewController else {
            return
        }
        let completedViewIndex = keySyncWizard.views.count - 1
        keySyncWizard.goTo(index: completedViewIndex)
    }

    func showError(error: Error?, completion: ((KeySyncErrorResponse) -> ())? = nil) {
        guard let viewController = presenter else {
            Log.shared.errorAndCrash("No Presenter")
            return
        }

        KeySyncErrorView.presentKeySyncError(viewController: viewController, error: error) {
            action in
            switch action {
            case .tryAgain:
                completion?(.tryAgain)
            case .notNow:
                completion?(.notNow)
            }
        }
    }
}
