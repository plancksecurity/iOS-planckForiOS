//
//  PEPUtils+Handshake.swift
//  MessageModel
//
//  Created by Xavier Algarra on 03/02/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

/// Util that contains all handshake related actions.
public protocol TrustManagementUtilProtocol: class {
    
    /// Method to obtain the related trustwords for an identity.
    /// - Parameters:
    ///   - SelfIdentity: self identity to do handshake.
    ///   - partnerIdentity: partner identity to do handshake.
    ///   - language: language code in ISO 639-1
    ///   - long: if false will return only 5 words, if true will return all posible trustwords for both identities.
    ///    - completion returns the result if available, returns nil otherwize
    /// For example absense of fingerprints, or a failure in the session. If so will be nil.
    func getTrustwords(for SelfIdentity: Identity, and partnerIdentity: Identity,
                       language: String,
                       long: Bool,
                       completion: @escaping (String?)->Void)

    func getTrustwords(forFpr1 fpr1: String,
                       fpr2: String,
                       language: String,
                       full: Bool,
                       completion: @escaping (String?)->Void)
    
    /// Confirms trust on a partner identity.
    /// - Parameters:
    ///   - partnerIdentity: The partner identity to deny trust on
    ///   - completion: A block that gets called after the action has finished
    func confirmTrust(for partnerIdentity: Identity,
                      completion: @escaping (Error?) -> ())

    /// Denies trust on a partner identity.
    /// - Parameters:
    ///   - partnerIdentity: The partner identity to deny trust on
    ///   - completion: A block that gets called after the action has finished
    func denyTrust(for partnerIdentity: Identity,
                   completion: @escaping (Error?) -> ())

    /// Asynchronously resets trust for a partner identity,
    /// undoing any previous trust or mistrust action.
    /// - Parameters:
    ///   - partnerIdentity: The partner identity
    ///   - fingerprint: The fingerprint of the identity
    ///   - completion: A block that gets called after the action has finished.
    func undoMisstrustOrTrust(for partnerIdentity: Identity,
                              fingerprint: String?,
                              completion: @escaping (Error?) -> ())
    
    /// Method that reset all information about the partner identity
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func resetTrust(for partnerIdentity: Identity?, completion: @escaping () -> ())

    /// Calls the completion block with a list of available languages codes
    /// in ISO 639-1 for the self identity
    func languagesList(completion: @escaping ([String]) -> ())
    
    func getFingerprint(for identity: Identity,
                        completion: @escaping (String?) -> ())

    /// - Parameter message: The message to generate the handshake combinations.
    /// - returns: The possible handshake combinations.
    func handshakeCombinations(message: Message,
                               completion: @escaping ([TrustManagementUtil.HandshakeCombination])->Void)

    /// - Parameter identities: The identities to generate the handshake combinations
    /// - returns: The possible handshake combinations.
    func handshakeCombinations(identities: [Identity],
                               completion: @escaping ([TrustManagementUtil.HandshakeCombination])->Void)
}

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
        PEPAsyncSession().getTrustwordsIdentity1(identitySelf, identity2: identityPartner, language: language, full: full, errorCallback: { (error) in
            Log.shared.error("%@", "\(error)")
            completion(nil)
        }) { (trustwords) in
            completion(trustwords)
        }
    }
}

// MARK: - TrustManagementUtilProtocol

extension TrustManagementUtil : TrustManagementUtilProtocol {
    public func languagesList(completion: @escaping ([String]) -> ()) {
        PEPAsyncSession().languageList({ error in
            Log.shared.error("Missing lenguage list")
            completion([])
        }) { langs in
            completion(langs.map { $0.code })
        }
    }

    public func getTrustwords(forFpr1 fpr1: String,//BUFF: wip
                              fpr2: String,
                              language: String,
                              full: Bool,
                              completion: @escaping (String?)->Void) {
        PEPAsyncSession().getTrustwordsFpr1(fpr1, fpr2: fpr2, language: language, full: full, errorCallback: { (error) in
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
        PEPAsyncSession().mySelf(selfPEPIdentity, errorCallback: { (error) in
            Log.shared.errorAndCrash(error: error)
            success = false
            group.leave()
        }) { (updatedOwnIdentity) in
            selfPEPIdentity = updatedOwnIdentity
            PEPAsyncSession().update(partnerPEPIdentity,
                                     errorCallback: { _ in
                                        Log.shared.error("unable to get the fingerprints")
                                        success = false
                                        group.leave()
            }) { updatedPartnerIdentity in
                partnerPEPIdentity = updatedPartnerIdentity
                PEPAsyncSession().isPEPUser(updatedPartnerIdentity,
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

        PEPAsyncSession().update(partnerPEPIdentity,
                                 errorCallback: { error in
                                    logError()
                                    completion(error)
        }) { identity in
            PEPAsyncSession().trustPersonalKey(identity,
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

        PEPAsyncSession().update(partnerPEPIdentity,
                                 errorCallback: { error in
                                    logError()
                                    completion(error)
        }) { identity in
            PEPAsyncSession().keyMistrusted(identity,
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

        PEPAsyncSession().update(partnerPEPIdentity,
                                 errorCallback: { error in
                                    logError()
                                    completion(error)
        }) { identity in
            if let fps = fingerprint {
                identity.fingerPrint = fps
            }
            PEPAsyncSession().keyResetTrust(identity,
                                            errorCallback: { error in
                                                logError()
                                                completion(error)
            }) {
                completion(nil)
            }
        }
    }

    public func resetTrust(for partnerIdentity: Identity?, completion: @escaping () -> ()) {
        partnerIdentity?.resetTrust(completion: completion)
    }

    public func getFingerprint(for identity: Identity,
                               completion: @escaping (String?) -> ()) {
        let pepIdentity = identity.pEpIdentity()
        PEPAsyncSession().update(pepIdentity,
                                 errorCallback: { _ in
                                    Log.shared.error("some went wrong getting the fingerprint for one identity")
                                    completion(nil)
        }) { identity in
            completion(identity.fingerPrint)
        }
    }

    public func handshakeCombinations(identities: [Identity],
                                      completion: @escaping ([HandshakeCombination])->Void) {
        let ownIdentities = identities.filter { $0.isMySelf }
        let ownIdentitiesWithKeys = ownIdentities.filter { $0.fingerprint != nil }//!!!: IOS-2325_!
        let partnerIdenties = identities.filter { !$0.isMySelf }

        var handshakableIdentities = [Identity]()
        let group = DispatchGroup()
        for partnerIdentity in partnerIdenties {
            group.enter()
            partnerIdentity.cdObject.canInvokeHandshakeAction { (canInvoke) in
                if canInvoke {
                    handshakableIdentities.append(partnerIdentity)
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            var combinations = [HandshakeCombination]()
            for ownId in ownIdentitiesWithKeys {
                for partnerId in handshakableIdentities {
                    let combination = HandshakeCombination(ownIdentity: ownId, partnerIdentity: partnerId)
                    combinations.append(combination)
                }
            }
            let uniqueCombinations = Set(combinations)
            completion(Array(uniqueCombinations))
        }
    }

    public func handshakeCombinations(message: Message,
                                      completion: @escaping ([HandshakeCombination])->Void) {
        let me = message.parent.account.user
        guard let from = message.from else {
            Log.shared.errorAndCrash("Mail from no one?")
            completion([])
            return
        }
        let to = Set(message.to.allObjects.filter { !$0.isMySelf }) // I am in with `me` already
        let identities = [me, from] + Array(to)
        handshakeCombinations(identities: identities, completion: completion)
    }
}

extension TrustManagementUtil {
    
    /// Represents a combination of identities to do a Handshake.
    public struct HandshakeCombination: Hashable {
        public let ownIdentity: Identity
        public let partnerIdentity: Identity

        public func hash(into hasher: inout Hasher) {
            hasher.combine(ownIdentity)
            hasher.combine(partnerIdentity)
        }
    }
}
