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
    func getTrustwords(for SelfIdentity: Identity, and partnerIdentity: Identity, language: String, long: Bool) throws -> String?
    
    /// Method to confirm trust for an indentity.
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func confirmTrust(for partnerIdentity: Identity)
    
    /// Method to deny trust for an indentity.
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func denyTrust(for partnerIdentity: Identity)
    
    /// Method to reset trust for an identity.
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func undoMisstrustOrTrust(for partnerIdentity: Identity, fingerprint: String?)
    
    /// Method that reset all information about the partner identity
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    func resetTrust(for partnerIdentity: Identity?)
    
    /// - returns: List of available languages codes in ISO 639-1 for the self identity
    func languagesList() -> [String]?
    
    /// Method that returns the actual fingerprints for the identity if there are ones, else will return nil
    /// - Parameter Identity: Identity in which the action will be taken.
    /// - returns: fingerprint of key of given identity if any, nil otherwize.
    func getFingerprint(for Identity: Identity) -> String?
    
    /// - Parameter message: The message to generate the handshake combinations.
    /// - returns: The possible handshake combinations.
    func handshakeCombinations(message: Message) -> [TrustManagementUtil.HandshakeCombination]

    /// - Parameter identities: The identities to generate the handshake combinations
    /// - returns: The possible handshake combinations.
    func handshakeCombinations(identities: [Identity]) -> [TrustManagementUtil.HandshakeCombination]
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
                             full: Bool) -> String? {
        do {
            return try PEPSession().getTrustwordsIdentity1(identitySelf,
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
    public func languagesList() -> [String]? {
        do {
            let languages = try PEPSession().languageList()
            return languages.map { $0.code }
        } catch {
            Log.shared.error("Missing lenguage list")
            return nil
        }
    }

    public func getTrustwords(for SelfIdentity: Identity, and partnerIdentity: Identity, language: String, long: Bool) -> String? {
        let selfPEPIdentity = SelfIdentity.pEpIdentity()
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()
        var isPartnerpEpUser = false
        do{
            try PEPSession().mySelf(selfPEPIdentity)
            try PEPSession().update(partnerPEPIdentity)
            isPartnerpEpUser = try PEPSession().isPEPUser(partnerPEPIdentity).boolValue
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
                return determineTrustwords(identitySelf: selfPEPIdentity,
                                           identityPartner: partnerPEPIdentity,
                                           language: language,
                                           full: long)
        }
    }
            
    public func confirmTrust(for partnerIdentity: Identity) {
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()
        do {
            try PEPSession().update(partnerPEPIdentity)
            try PEPSession().trustPersonalKey(partnerPEPIdentity)
        } catch {
            Log.shared.error("Not posible to perform confirm trust action")
        }
    }
    
    public func denyTrust(for partnerIdentity: Identity) {
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()
        do {
            try PEPSession().update(partnerPEPIdentity)
            try PEPSession().keyMistrusted(partnerPEPIdentity)
        } catch {
            Log.shared.error("not posible to perform deny trust action")
        }
    }

    public func undoMisstrustOrTrust(for partnerIdentity: Identity, fingerprint: String?) {
        let partnerPEPIdentity = partnerIdentity.pEpIdentity()
        do {
            try PEPSession().update(partnerPEPIdentity)
            if let fps = fingerprint {
                partnerPEPIdentity.fingerPrint = fps
            }
            try PEPSession().keyResetTrust(partnerPEPIdentity)
        } catch {
            Log.shared.error("Not posible to perform reset trust action")
        }
    }

    public func resetTrust(for partnerIdentity: Identity?) {
        partnerIdentity?.resetTrust()
    }

    public func getFingerprint(for identity: Identity) -> String? {
        let pepIdentity = identity.pEpIdentity()
        do {
            try PEPSession().update(pepIdentity)
            return pepIdentity.fingerPrint
        } catch {
            Log.shared.error("some went wrong getting the fingerprint for one identity")
            return nil
        }
    }

    public func handshakeCombinations(identities: [Identity]) -> [HandshakeCombination] {
        let ownIdentities = identities.filter { $0.isMySelf }
        let ownIdentitiesWithKeys = ownIdentities.filter { $0.fingerprint != nil }
        let partnerIdenties = identities.filter { !$0.isMySelf }
        let handshakableIdentities = partnerIdenties.filter { $0.cdObject.canInvokeHandshakeAction() }
        var combinations = [HandshakeCombination]()
        for ownId in ownIdentitiesWithKeys {
            for partnerId in handshakableIdentities {
                let combination = HandshakeCombination(ownIdentity: ownId, partnerIdentity: partnerId)
                combinations.append(combination)
            }
        }
        return combinations
    }

    public func handshakeCombinations(message: Message) -> [HandshakeCombination] {
        //If "from" is myself -the current user- it is outgoing message. Otherwise is incoming.
        if let from = message.from, from.isMySelf {
            var identities = Array(message.to)
            identities.append(from)
            return handshakeCombinations(identities:identities)
        } else if let to = message.to.filter({$0.isMySelf}).first, let from = message.from {
            return handshakeCombinations(identities:[to, from])
        }

        Log.shared.error("Error creating the handshake combinations.")
        return [HandshakeCombination]()
    }
}

extension TrustManagementUtil {
    
    /// Represents a combination of identities to do a Handshake.
    public struct HandshakeCombination {
        public let ownIdentity: Identity
        public let partnerIdentity: Identity
    }
}
