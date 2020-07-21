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
    /// - returns: The trustwords generated according to the parameters. If fails, nil.
    /// For example absense of fingerprints, or a failure in the session. If so will be nil.
    func getTrustwords(for SelfIdentity: Identity, and partnerIdentity: Identity, language: String, long: Bool) throws -> String?//!!!: IOS-2325_!
    
    /// Method to confirm trust for an indentity.
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func confirmTrust(for partnerIdentity: Identity)//!!!: IOS-2325_!
    
    /// Method to deny trust for an indentity.
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func denyTrust(for partnerIdentity: Identity)//!!!: IOS-2325_!
    
    /// Method to reset trust for an identity.
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func undoMisstrustOrTrust(for partnerIdentity: Identity, fingerprint: String?)//!!!: IOS-2325_!
    
    /// Method that reset all information about the partner identity
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func resetTrust(for partnerIdentity: Identity?)//!!!: IOS-2325_!
    
    /// - returns: List of available languages codes in ISO 639-1 for the self identity
    func languagesList() -> [String]?//!!!: IOS-2325_!
    
    /// Method that returns the actual fingerprints for the identity if there are ones, else will return nil
    /// - Parameter Identity: Identity in which the action will be taken.
    /// - returns: fingerprint of key of given identity if any, nil otherwize.
    func getFingerprint(for Identity: Identity) -> String?//!!!: IOS-2325_!
    
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
    
    private func determineTrustwords(identitySelf: PEPIdentity,//!!!: IOS-2325_!
                             identityPartner: PEPIdentity,
                             language: String,
                             full: Bool) -> String? {
        do {
            return try PEPSession().getTrustwordsIdentity1(identitySelf,//!!!: IOS-2325_!
                                                           identity2: identityPartner,
                                                           language: language,
                                                           full: full)
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            return nil
        }
    }
}

// MARK: - TrustManagementUtilProtocol

extension TrustManagementUtil : TrustManagementUtilProtocol {
    public func languagesList() -> [String]? {//!!!: IOS-2325_!
        do {
            let languages = try PEPSession().languageList()//!!!: IOS-2325_!
            return languages.map { $0.code }
        } catch {
            Log.shared.error("Missing lenguage list")
            return nil
        }
    }

    public func getTrustwords(for SelfIdentity: Identity,//!!!: IOS-2325_!
                              and partnerIdentity: Identity,
                              language: String,
                              long: Bool) -> String? {
        let selfPEPIdentity = SelfIdentity.pEpIdentity()
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()
        var isPartnerpEpUser = false
        do{
            try PEPSession().mySelf(selfPEPIdentity)//!!!: IOS-2325_!
            try PEPSession().update(partnerPEPIdentity)//!!!: IOS-2325_!
            isPartnerpEpUser = try PEPSession().isPEPUser(partnerPEPIdentity).boolValue//!!!: IOS-2325_!
        } catch {
            Log.shared.error("unable to get the fingerprints")
        }

        if !isPartnerpEpUser, let fprSelf = selfPEPIdentity.fingerPrint,
            let fprPartner = partnerPEPIdentity.fingerPrint  {
            // partner is a PGP user
            let fprPrettySelf = fprSelf.prettyFingerPrint()
            let fprPrettyPartner = fprPartner.prettyFingerPrint()
            return "\(partnerIdentity.userNameOrAddress):\n\(fprPrettyPartner)\n\n" + "\(SelfIdentity.userNameOrAddress):\n\(fprPrettySelf)"
        } else {
                return determineTrustwords(identitySelf: selfPEPIdentity,//!!!: IOS-2325_!
                                           identityPartner: partnerPEPIdentity,
                                           language: language,
                                           full: long)
        }
    }
            
    public func confirmTrust(for partnerIdentity: Identity) {//!!!: IOS-2325_!
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()
        do {
            try PEPSession().update(partnerPEPIdentity)//!!!: IOS-2325_!
            try PEPSession().trustPersonalKey(partnerPEPIdentity)//!!!: IOS-2325_!
        } catch {
            Log.shared.error("Not posible to perform confirm trust action")
        }
    }
    
    public func denyTrust(for partnerIdentity: Identity) {//!!!: IOS-2325_!
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()
        do {
            try PEPSession().update(partnerPEPIdentity)//!!!: IOS-2325_!
            try PEPSession().keyMistrusted(partnerPEPIdentity)//!!!: IOS-2325_!
        } catch {
            Log.shared.error("not posible to perform deny trust action")
        }
    }

    public func undoMisstrustOrTrust(for partnerIdentity: Identity, fingerprint: String?) {//!!!: IOS-2325_!
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()
        do {
            try PEPSession().update(partnerPEPIdentity)//!!!: IOS-2325_!
            if let fps = fingerprint {
                partnerPEPIdentity.fingerPrint = fps
            }
            try PEPSession().keyResetTrust(partnerPEPIdentity)//!!!: IOS-2325_!
        } catch {
            Log.shared.error("Not posible to perform reset trust action")
        }
    }

    public func resetTrust(for partnerIdentity: Identity?) {//!!!: IOS-2325_!
        partnerIdentity?.resetTrust()//!!!: IOS-2325_!
    }

    public func getFingerprint(for identity: Identity) -> String? {//!!!: IOS-2325_!
        let pepIdentity = identity.pEpIdentity()
        do {
            try PEPSession().update(pepIdentity)//!!!: IOS-2325_!
            return pepIdentity.fingerPrint
        } catch {
            Log.shared.error("some went wrong getting the fingerprint for one identity")
            return nil
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
