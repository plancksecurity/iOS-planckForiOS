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
    private var pEpSyncWizard: KeySyncWizardViewController?

    init() {
        registerForKeySyncDeviceGroupStateChangeNotification()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - KeySyncDeviceGroupStateChangeNotification

extension KeySyncHandshakeService {

    func registerForKeySyncDeviceGroupStateChangeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceGroupStateChangeNotification(_:)),
                                               name: Notification.Name.pEpDeviceGroupStateChange,
                                               object: nil)
    }

    @objc
    private func handleDeviceGroupStateChangeNotification(_ notification: Notification) {
        guard let wizzard = pEpSyncWizard else {
            // This is a valid case. pEpSyncWizard is initiated on demand and we might currently not
            // display the wizzard.
            return
        }
        DispatchQueue.main.async {
            guard !wizzard.isCurrentlyShowingSuccessfullyGroupedView else {
                // We want to dismiss any wizzard view but the SuccessfullyGrouped one.
                return
            }

            wizzard.dismiss()
        }
    }
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
        DispatchQueue.main.async { [weak self] in
            if let pEpModal = presenter.presentedViewController,
                UIHelper.isPEPModal(viewController: pEpModal) {
                viewController = pEpModal
            }
            self?.pEpSyncWizard = viewController.presentKeySyncWizard(meFPR: meFPR,
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
    }

    func cancelHandshake() {
        DispatchQueue.main.async { [weak self] in
            guard let keySyncWizard = self?.presenter?.presentedViewController as? KeySyncWizardViewController else {
                return
            }
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
        DispatchQueue.main.async { [weak self] in
            guard let presentingViewController = self?.pEpSyncWizard?.presentingViewController else {
                //presentingViewController is nil then, pEpSyncWizard failed to be shown.
                //So we call tryAgain to engine, to give it a another try to show pEpSyncWizard.
                completion?(.tryAgain)
                return
            }

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
