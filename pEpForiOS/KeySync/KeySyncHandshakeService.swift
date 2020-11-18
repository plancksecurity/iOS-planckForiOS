//
//  KeySyncHandshakeService.swift
//  pEp
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

class KeySyncHandshakeService {
    private weak var pEpSyncWizard: KeySyncWizardViewController?

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

extension KeySyncHandshakeService: KeySyncServiceHandshakeHandlerProtocol {
    func showHandshake(meFingerprint: String?,
                       partnerFingerprint: String?,
                       isNewGroup: Bool,
                       completion: ((KeySyncHandshakeResult)->())? = nil) {

        guard let meFPR = meFingerprint, let partnerFPR = partnerFingerprint else {
            Log.shared.errorAndCrash("Missing FPRs")
            return
        }

        // pEpSyncWizard should be presented over other pEp modals (like Login, Tutorial, etc)
        // if a pEpModal is being presented. We present pEpSyncWizard over it.
        // Else the viewController to present it
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.pEpSyncWizard = UIUtils.showKeySyncWizard(meFPR: meFPR,
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
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.pEpSyncWizard?.dismiss()
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
    func showError(error: Error?,
                   completion: ((KeySyncErrorResponse) -> ())? = nil) {

        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard let presentingViewController = me.pEpSyncWizard?.presentingViewController else {
                //presentingViewController is nil then, pEpSyncWizard failed to be shown.
                //So we call tryAgain to engine, to give it a another try to show pEpSyncWizard.
                completion?(.tryAgain)
                return
            }

            let isNewGroup = me.pEpSyncWizard?.isNewGroup ?? true

            me.pEpSyncWizard?.dismiss(animated: true) {
                KeySyncErrorView.presentKeySyncError(viewController: presentingViewController,
                                                     isNewGroup: isNewGroup,
                                                     error: error) {
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
    }
}
