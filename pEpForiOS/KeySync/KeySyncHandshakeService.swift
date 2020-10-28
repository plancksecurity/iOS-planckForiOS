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

    public func registerForKeySyncDeviceGroupStateChangeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeviceGroupStateChangeNotification(_:)),
                                               name: Notification.Name.pEpDeviceGroupStateChange,
                                               object: nil)
    }

    @objc
    private func handleDeviceGroupStateChangeNotification(_ notification: Notification) {
        guard let wizard = pEpSyncWizard else {
            // This is a valid case. pEpSyncWizard is initiated on demand and we might currently not
            // display the wizard.
            return
        }
        DispatchQueue.main.async {
            guard !wizard.isCurrentlyShowingSuccessfullyGroupedView else {
                // We want to dismiss any wizard view but the SuccessfullyGrouped one.
                return
            }
            wizard.dismiss()
        }
    }
}

extension KeySyncHandshakeService: KeySyncServiceHandshakeHandlerProtocol {

    /// Show handshake wizard
    ///
    /// - Parameters:
    ///   - meFingerprint: The fingerprints of the current user
    ///   - partnerFingerprint: The fingerprints of the comunication partner of the current user
    ///   - isNewGroup: Indicates if it is a new group creation
    ///   - completion: callback that will be executed in case the user accepts, cancels or declines.
    public func showHandshake(meFingerprint: String?,
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

    public func cancelHandshake() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.pEpSyncWizard?.dismiss()
        }
    }

    public func showSuccessfullyGrouped() {
        guard let pEpSyncWizard = pEpSyncWizard else {
            // Valid case. We might have been dismissed already.
            return
        }
        let completedViewIndex = pEpSyncWizard.views.count - 1
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.pEpSyncWizard?.goTo(index: completedViewIndex)
        }
    }

    // We must dismiss pEpSyncWizard before presenting pEpSyncWizard error view.
    public func showError(error: Error?, completion: ((KeySyncErrorResponse) -> ())? = nil) {
        let isNewGroup = pEpSyncWizard?.isNewGroup ?? true
        DispatchQueue.main.async { [weak self] in
            guard let me = self, let pEpSyncWizard = me.pEpSyncWizard else {
                // Valid case. We might have been dismissed already.
                UIUtils.showKeySyncErrorView(isNewGroup: isNewGroup, error: error, completion: completion)
                return
            }
            pEpSyncWizard.dismiss(animated: true) {
                UIUtils.showKeySyncErrorView(isNewGroup: isNewGroup, error: error, completion: completion)
            }
        }
    }
}
