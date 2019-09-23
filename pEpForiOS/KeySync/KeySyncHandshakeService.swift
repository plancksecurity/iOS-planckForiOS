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
    
    private weak var pEpSyncWizard: PEPPageViewController?
}

extension KeySyncHandshakeService: KeySyncServiceHandshakeDelegate {
    
    func showHandshake(me: PEPIdentity,
                       partner: PEPIdentity,
                       isNewGroup: Bool,
                       completion: ((PEPSyncHandshakeResult)->())? = nil) {

        guard let presenter = presenter else {
            Log.shared.errorAndCrash("No Presenter")
            return
        }
        guard let meFPR = me.fingerPrint, let partnerFPR = partner.fingerPrint else {
            Log.shared.errorAndCrash("Missing FPRs")
            return
        }

        var viewController = presenter
        if let pEpModal = presenter.presentedViewController,
            UIHelper.isPEPModal(viewController: pEpModal) {
            viewController = pEpModal
        }
        pEpSyncWizard = viewController.presentKeySyncWizard(meFPR: meFPR,
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
        guard let pEpSyncWizard = pEpSyncWizard else {
            return
        }
        let completedViewIndex = pEpSyncWizard.views.count - 1
        pEpSyncWizard.goTo(index: completedViewIndex)
    }

    func showError(error: Error?, completion: ((KeySyncErrorResponse) -> ())? = nil) {
        guard let presentingViewController = pEpSyncWizard?.presentingViewController else {
            Log.shared.errorAndCrash("No Presenter")
            return
        }

        pEpSyncWizard?.dismiss(animated: true, completion: {
            KeySyncErrorView.presentKeySyncError(viewController: presentingViewController, error: error) {
                action in
                switch action {
                case .tryAgain:
                    completion?(.tryAgain)
                case .notNow:
                    completion?(.notNow)
                }
            }
        })
    }
}
