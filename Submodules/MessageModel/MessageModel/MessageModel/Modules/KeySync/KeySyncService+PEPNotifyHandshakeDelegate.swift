//
//  KeySyncService+PEPNotifyHandshakeDelegate.swift
//  MessageModel
//
//  Created by Andreas Buff on 07.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework
import pEpIOSToolbox

extension KeySyncService: PEPNotifyHandshakeDelegate {

    func engineShutdownKeySync() {
        postKeySyncDisabledByEngineNotification()
    }

    func notifyHandshake(_ object: UnsafeMutableRawPointer?,
                         me: PEPIdentity,
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
            guard let thePartner = partner else {
                Log.shared.errorAndCrash(message: "Expected partner identity")
                return .illegalValue
            }
            fastPollingDelegate?.enableFastPolling()
            showHandshakeAndHandleResult(inBetween: me, and: thePartner, isNewGroup: false)

        case .initFormGroup:
            guard let thePartner = partner else {
                Log.shared.errorAndCrash(message: "Expected partner identity")
                return .illegalValue
            }
            fastPollingDelegate?.enableFastPolling()
            showHandshakeAndHandleResult(inBetween: me, and: thePartner, isNewGroup: true)

        case .timeout:
            fastPollingDelegate?.disableFastPolling()
            showHandShakeErrorAndHandleResult(error: KeySyncError.timeOut)

        case .acceptedDeviceAdded, .acceptedGroupCreated, .acceptedDeviceAccepted:
            fastPollingDelegate?.disableFastPolling()
            handshakeHandler?.showSuccessfullyGrouped()
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

        // Other
        case .undefined:
            handshakeHandler?.cancelHandshake()
            fastPollingDelegate?.disableFastPolling()
            Log.shared.errorAndCrash("undefined case")
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

    private func showHandshakeAndHandleResult(inBetween me: PEPIdentity,
                                              and partner: PEPIdentity,
                                              isNewGroup: Bool) {
        handshakeHandler?.showHandshake(meFingerprint: me.fingerPrint,
                                        partnerFingerprint: partner.fingerPrint,
                                        isNewGroup: isNewGroup) {
                                            [weak self] result in
                                            if result == .cancel || result == .rejected {
                                                self?.fastPollingDelegate?.disableFastPolling()
                                            }
                                            PEPSession().deliver(result.pEpSyncHandshakeResult(),
                                                                 identitiesSharing: [me, partner],
                                                                 errorCallback: { (error: Error) in
                                                                    Log.shared.errorAndCrash("Error delivering handshake result: %@",
                                                                                             error.localizedDescription)
                                            }) {
                                                // Caller doesn't care about the result
                                            }
        }
    }

    private func showHandShakeErrorAndHandleResult(error: Error) {
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
