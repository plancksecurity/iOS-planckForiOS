//
//  KeySyncService+PEPNotifyHandshakeDelegate.swift
//  MessageModel
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapter
import PlanckToolbox

extension KeySyncService: PEPNotifyHandshakeDelegate {
    func notifyHandshake(_ object: UnsafeMutableRawPointer?,
                         me: PEPIdentity?,
                         partner: PEPIdentity?,
                         signal: PEPSyncHandshakeSignal) -> PEPStatus {
        switch signal {
        // notificaton of actual group status
        case .sole:
            postDeviceGroupStateChangeNotification(newState: .sole)
        case .inGroup:
            postDeviceGroupStateChangeNotification(newState: .grouped)

        // request show handshake dialog
        case .initAddOurDevice, .initAddOtherDevice:
            if !keySyncEnabled {
                // User has not indicated the wish to sync, so ignore.
                break
            }

            guard let theMe = me else {
                Log.shared.errorAndCrash(message: "Expected own identity")
                return .illegalValue
            }

            guard let thePartner = partner else {
                Log.shared.errorAndCrash(message: "Expected partner identity")
                return .illegalValue
            }

            fastPollingDelegate?.enableFastPolling()
            showHandshakeAndHandleResult(inBetween: theMe, and: thePartner, isNewGroup: false)

        case .initFormGroup:
            if !keySyncEnabled {
                // User has not indicated the wish to sync, so ignore.
                break
            }

            guard let theMe = me else {
                Log.shared.errorAndCrash(message: "Expected own identity")
                return .illegalValue
            }

            guard let thePartner = partner else {
                Log.shared.errorAndCrash(message: "Expected partner identity")
                return .illegalValue
            }

            fastPollingDelegate?.enableFastPolling()
            showHandshakeAndHandleResult(inBetween: theMe, and: thePartner, isNewGroup: true)

        case .timeout:
            if !keySyncEnabled {
                // User has not indicated the wish to sync, so ignore.
                break
            }

            fastPollingDelegate?.disableFastPolling()
            showHandshakeErrorAndHandleResult(error: KeySyncError.timeOut)

        case .acceptedDeviceAdded, .acceptedGroupCreated, .acceptedDeviceAccepted:
            if !keySyncEnabled {
                // User has not indicated the wish to sync, so ignore.
                break
            }

            fastPollingDelegate?.disableFastPolling()
            handshakeHandler?.handleSuccessfullyGrouped()
            tryRedecryptYetUndecryptableMessages()

        case .passphraseRequired:
            passphraseProvider.showEnterPassphrase(triggeredWhilePEPSync: true) { [weak self] passphrase in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                guard let pp = passphrase else {
                    me.stop()
                    return
                }
                try? PassphraseUtil().newPassphrase(pp)
            }

        case .start:
            // Corresponds to SYNC_NOTIFY_START in the engine, only needed for desktop
            break

        case .stop:
            if keySyncEnabled {
                // User has requested key sync, but then canceled. Handle this.
                handshakeHandler?.cancelHandshake()

                // For now, disable sync again.
                postKeySyncDisabledByEngineNotification()
            }

        case .outgoingRatingChange:
            outgoingRatingService.handleOutgoingRatingChange()

        // Other
        case .undefined:
            handshakeHandler?.cancelHandshake()
            fastPollingDelegate?.disableFastPolling()
            Log.shared.errorAndCrash("undefined case")

        case .groupInvitation:
            // TODO
            Log.shared.errorAndCrash(".groupInvitation has to be implemented")
        }

        return .OK
    }
}

// MARK: - KeySyncErrors

extension KeySyncService {
    
    enum KeySyncError: Error {
        case timeOut
    }
}

// MARK: - Private

extension KeySyncService {

    private func postDeviceGroupStateChangeNotification(newState: DeviceGroupState) {
        NotificationCenter.default.post(name: Notification.Name.pEpDeviceGroupStateChange,
                                        object: self,
                                        userInfo: [DeviceGroupState.notificationInfoDictKeyDeviceGroupState:newState])
    }

    private func postKeySyncDisabledByEngineNotification() {
        NotificationCenter.default.post(name: Notification.Name.pEpKeySyncDisabledByEngine,
                                        object: self,
                                        userInfo: nil)
    }

    private func showHandshakeAndHandleResult(inBetween me: PEPIdentity, and partner: PEPIdentity, isNewGroup: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let keySyncHandshakeData = KeySyncHandshakeData(email: me.address,
                                                            username: me.userName,
                                                            fingerprintLocal: me.fingerPrint,
                                                            fingerprintOther: partner.fingerPrint,
                                                            isNewGroup: isNewGroup)
            strongSelf.handshakeHandler?.showHandshake(keySyncHandshakeData: keySyncHandshakeData) { result in
                if result == .cancel || result == .rejected {
                    strongSelf.fastPollingDelegate?.disableFastPolling()
                }
                PEPSession().deliver(result.pEpSyncHandshakeResult(),
                                     identitiesSharing: [me, partner],
                                     errorCallback: { (error: Error) in
                    if error.isPassphraseError {
                        Log.shared.error("Error delivering handshake result: %@", error.localizedDescription)
                    } else {
                        Log.shared.errorAndCrash("%@", error.localizedDescription)
                    }}) {
                        // Caller doesn't care about the result
                    }
            }
        }
    }

    private func showHandshakeErrorAndHandleResult(error: Error) {
        handshakeHandler?.showError(error: error) {
            [weak self] keySyncErrorResponse in
            switch keySyncErrorResponse {
            case .notNow:
                // The user decided not try try again now, but later.
                // Do nothing.
                break
            case .tryAgain:
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                // The user wants to try to KeySync again. We stop and start again to send a new beacon imediatelly.
                me.stop()
                me.start()
            }
        }
    }

    /// Marks all yet undecryptable messages to retry decryption.
    /// Use after we got new keys.
    private func tryRedecryptYetUndecryptableMessages() {
        DispatchQueue.global(qos: .userInitiated).async {
            let moc = Stack.shared.newPrivateConcurrentContext
            moc.performAndWait {
                CdMessage.markAllUndecryptableMessagesForRetryDecrypt(context: moc)
                moc.saveAndLogErrors()
            }
        }
    }
}
