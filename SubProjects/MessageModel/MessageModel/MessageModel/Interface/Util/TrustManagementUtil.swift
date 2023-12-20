//
//  PEPUtils+Handshake.swift
//  MessageModel
//
//  Created by Xavier Algarra on 03/02/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapter

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

/// This class acts as an intermediary to access different functions of the engine adapter.
/// Among them: obtain trustwords, obtain the list of available languages, confirm or deny trust,
/// undo a confirmation or rejection of trust, reset an identity, obtain the fingerprint of a
/// certain identity, obtain the combinations of possible handshakes of a set of identities.
public class TrustManagementUtil {

    /// Expose the init outside MM.
    public init() {}

    private func determineTrustwords(identitySelf: PEPIdentity,
                                     identityPartner: PEPIdentity,
                                     language: String,
                                     full: Bool,
                                     completion: @escaping (String?)->Void) {
        PEPSession().getTrustwordsIdentity1(identitySelf, identity2: identityPartner, language: language, full: full, errorCallback: { (error) in
            Log.shared.log(error: error)
            completion(nil)
        }) { (trustwords) in
            completion(trustwords)
        }
    }
}

// MARK: - TrustManagementUtilProtocol

extension TrustManagementUtil : TrustManagementUtilProtocol {
    public func languagesList(acceptedLanguages: [String]?,
                              completion: @escaping ([String]) -> ()) {
        PEPSession().languageList({ error in
            Log.shared.error("Missing lenguage list")
            completion([])
        }) { langs in
            if let acceptedLanguages = acceptedLanguages, !acceptedLanguages.isEmpty {
                let filteredLanguages = langs.filter({acceptedLanguages.contains($0.code)})
                DispatchQueue.main.async {
                    completion(filteredLanguages.map { $0.code })
                }
            } else {
                DispatchQueue.main.async {
                    completion(langs.map { $0.code })
                }
                
            }
        }
    }

    public func getTrustwords(email: String,
                              username: String?,
                              fpr1: String,
                              fpr2: String,
                              language: String,
                              full: Bool,
                              completion: @escaping (String?) -> Void) {
        let pEpIdentityLocal = PEPIdentity(address: email,
                                           userID: nil,
                                           userName: username,
                                           isOwn: true)
        pEpIdentityLocal.fingerPrint = fpr1

        let pEpIdentityOther = PEPIdentity(address: email,
                                           userID: nil,
                                           userName: username,
                                           isOwn: false)
        pEpIdentityOther.fingerPrint = fpr2

        PEPSession().getTrustwordsIdentity1(pEpIdentityLocal,
                                            identity2: pEpIdentityOther,
                                            language: language,
                                            full: full,
                                            errorCallback: { (error) in
            Log.shared.error("%@", error.localizedDescription)
            completion(nil)
        }) { (trustwords) in
            completion(trustwords)
        }
    }

    public func getTrustwords(for SelfIdentity: Identity,
                              and partnerIdentity: Identity,
                              language: String,
                              long: Bool,
                              completion: @escaping (String?)->Void) {
        var selfPEPIdentity = SelfIdentity.pEpIdentity()
        var partnerPEPIdentity = partnerIdentity.pEpIdentity()
        var isPartnerpEpUser = false
        let group = DispatchGroup()
        var success = true

        group.enter()
        PEPSession().mySelf(selfPEPIdentity, errorCallback: { (error) in
            if error.isPassphraseError {
                Log.shared.log(error: error)
            } else {
                Log.shared.errorAndCrash(error: error)
            }
            success = false
            group.leave()
        }) { (updatedOwnIdentity) in
            selfPEPIdentity = updatedOwnIdentity
            PEPSession().update(partnerPEPIdentity,
                                     errorCallback: { _ in
                                        Log.shared.error("unable to get the fingerprints")
                                        success = false
                                        group.leave()
            }) { updatedPartnerIdentity in
                partnerPEPIdentity = updatedPartnerIdentity
                PEPSession().isPEPUser(updatedPartnerIdentity,
                                            errorCallback: { _ in
                                                success = false
                                                group.leave()
                }) { pEpUserOrNot in
                    isPartnerpEpUser = pEpUserOrNot
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard success else {
                completion(nil)
                return
            }

            if !isPartnerpEpUser, let fprSelf = selfPEPIdentity.fingerPrint,
                let fprPartner = partnerPEPIdentity.fingerPrint  {
                // partner is a PGP user
                let fprPrettySelf = fprSelf.prettyFingerPrint()
                let fprPrettyPartner = fprPartner.prettyFingerPrint()
                completion("\(partnerIdentity.userNameOrAddress):\n\(fprPrettyPartner)\n\n" + "\(SelfIdentity.userNameOrAddress):\n\(fprPrettySelf)")
            } else {
                me.determineTrustwords(identitySelf: selfPEPIdentity,
                                    identityPartner: partnerPEPIdentity,
                                    language: language,
                                    full: long,
                                    completion: completion)
            }
        }
    }
            
    public func confirmTrust(for partnerIdentity: Identity,
                             completion: @escaping (Error?) -> ()) {
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()

        func logError() {
            Log.shared.error("Not posible to perform confirm trust action")
        }

        PEPSession().update(partnerPEPIdentity,
                                 errorCallback: { error in
                                    logError()
                                    completion(error)
        }) { identity in
            PEPSession().trustPersonalKey(identity,
                                               errorCallback: { error in
                                                logError()
                                                completion(error)
            }) {
                completion(nil)
            }
        }
    }

    public func denyTrust(for partnerIdentity: Identity,
                               completion: @escaping (Error?) -> ()) {
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()

        func logError() {
            Log.shared.error("not posible to perform deny trust action")
        }

        PEPSession().update(partnerPEPIdentity,
                                 errorCallback: { error in
                                    logError()
                                    completion(error)
        }) { identity in
            PEPSession().keyMistrusted(identity,
                                            errorCallback: { error in
                                                completion(error)
            }) {
                completion(nil)
            }
        }
    }

    public func undoMisstrustOrTrust(for partnerIdentity: Identity,
                                     fingerprint: String?,
                                     completion: @escaping (Error?) -> ()) {
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()

        func logError() {
            Log.shared.error("Not posible to perform reset trust action")
        }

        PEPSession().update(partnerPEPIdentity,
                                 errorCallback: { error in
                                    logError()
                                    completion(error)
        }) { identity in
            if let fps = fingerprint {
                // In case we are trying to undo a mistrust (already mistrusted the key of an
                // Identity), the Engine does not return an FPR, so the caller has to pass it as an
                // argument.
                identity.fingerPrint = fps
            }
            PEPSession().keyResetTrust(identity,
                                            errorCallback: { error in
                                                logError()
                                                completion(error)
            }) {
                completion(nil)
            }
        }
    }

    public func resetTrust(for partnerIdentity: Identity?,
                           completion: @escaping () -> (),
                           errorCallback: (() -> Void)? = nil) {
        guard let identity = partnerIdentity else {
            Log.shared.errorAndCrash("Identity must not be nil")
            return
        }
        identity.resetTrust(completion: completion, errorCallback: errorCallback)
    }

    public func getFingerprint(for identity: Identity,
                               completion: @escaping (String?) -> ()) {
        let pepIdentity = identity.pEpIdentity()
        PEPSession().update(pepIdentity,
                                 errorCallback: { _ in
                                    Log.shared.error("some went wrong getting the fingerprint for one identity")
                                    completion(nil)
        }) { identity in
            completion(identity.fingerPrint)
        }
    }

    public func handshakeCombinations(identities: [Identity],
                                      shouldAllowHandshakeActions: Bool = true,
                                      completion: @escaping ([HandshakeCombination]) -> Void) {
        let ownIdentities = identities.filter { $0.isMySelf }
        let partnerIdenties = identities.filter { !$0.isMySelf }

        let groupFingerprint = DispatchGroup()
        var ownIdentitiesWithKeys = [Identity]()
        for ident in ownIdentities {
            groupFingerprint.enter()
            ident.fingerprint() { fingerprint in
                if fingerprint != nil {
                    ownIdentitiesWithKeys.append(ident)
                }
                groupFingerprint.leave()
            }
        }

        groupFingerprint.notify(queue: DispatchQueue.main) {
            var handshakableIdentities = [Identity]()
            let groupHandshakeAction = DispatchGroup()
            for partnerIdentity in partnerIdenties {
                if shouldAllowHandshakeActions {
                    groupHandshakeAction.enter()
                    partnerIdentity.cdObject.canInvokeHandshakeAction { (canInvoke) in
                        if canInvoke {
                            handshakableIdentities.append(partnerIdentity)
                        }
                        groupHandshakeAction.leave()
                    }
                } else {
                    handshakableIdentities.append(partnerIdentity)
                }
            }
            groupHandshakeAction.notify(queue: DispatchQueue.main) {
                var combinations = [HandshakeCombination]()
                for ownId in ownIdentitiesWithKeys {
                    let safeOwnId = ownId.safeForSession(Session.main)
                    for partnerId in handshakableIdentities {
                        let safePartnerId = partnerId.safeForSession(Session.main)
                        let combination = HandshakeCombination(ownIdentity: safeOwnId, partnerIdentity: safePartnerId)
                        combinations.append(combination)
                    }
                }
                let uniqueCombinations = Set(combinations)
                completion(Array(uniqueCombinations))
            }
        }
    }

    public func handshakeCombinations(message: Message,
                                      shouldAllowHandshakeActions: Bool = true,
                                      completion: @escaping ([HandshakeCombination])->Void) {
        message.session.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let accountUser = message.parent.account.user
            guard let from = message.from else {
                Log.shared.errorAndCrash("Mail from no one?")
                completion([])
                return
            }
            let to = Set(message.to.allObjects.filter { !$0.isMySelf }) // I am in with `me` already
            let identities = [accountUser, from] + Array(to)
            me.handshakeCombinations(identities: identities, shouldAllowHandshakeActions: shouldAllowHandshakeActions, completion: completion)
        }
    }
}

extension TrustManagementUtil {
    
    /// Represents a combination of identities to do a Handshake.
    public struct HandshakeCombination: Hashable {
        public let ownIdentity: Identity
        public let partnerIdentity: Identity

        public func hash(into hasher: inout Hasher) {
            let safeOwnIdentity = ownIdentity.safeForSession(Session.main)
            let safePartnerIdentity = ownIdentity.safeForSession(Session.main)
            hasher.combine(safeOwnIdentity)
            hasher.combine(safePartnerIdentity)
        }
    }
}
