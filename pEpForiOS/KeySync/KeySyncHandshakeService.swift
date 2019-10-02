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
    
    private var pEpSyncWizard: PEPPageViewController?
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

        // pEpSyncWizard should be presented over other pEp modals (like Login, Tutorial, etc)
        // if a pEpModal is being presented. We present pEpSyncWizard over it.
        // Else the viewController to present it
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

    func showCurrentlyGroupingDevices() {
        //Ignoring for now. We show the syncing animation right away, when the user press Sync button.
        //So nothing to do here :-/
    }
    
    func cancelHandshake() {
        guard let keySyncWizard = presenter?.presentedViewController as? PEPPageViewController else {
            return
        }
        DispatchQueue.main.async {
            keySyncWizard.dismiss()
        }
    }
    
    func showSuccessfullyGrouped() {
        guard let pEpSyncWizard = pEpSyncWizard else {
            return
        }
        let completedViewIndex = pEpSyncWizard.views.count - 1
        DispatchQueue.main.async { [weak self] in
            self?.pEpSyncWizard?.goTo(index: completedViewIndex)
        }
    }

    // We must dismiss pEpSyncWizard before presenting pEpSyncWizard error view.
    func showError(error: Error?, completion: ((KeySyncErrorResponse) -> ())? = nil) {
        guard let presentingViewController = pEpSyncWizard?.presentingViewController else {
            //presentingViewController is nil then, pEpSyncWizard failed to be shown.
            //So we call tryAgain to engine, to give it a another try to show pEpSyncWizard.
            completion?(.tryAgain)
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.pEpSyncWizard?.dismiss(animated: true, completion: {
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
}
