//
//  TrustManagementUtilProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 2/3/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation

/// Util that contains all handshake related actions.
public protocol TrustManagementUtilProtocol: AnyObject {

    /// Method to obtain the related trustwords for an identity.
    /// - Parameters:
    ///   - SelfIdentity: self identity to do handshake.
    ///   - partnerIdentity: partner identity to do handshake.
    ///   - language: language code in ISO 639-1
    ///   - long: if false will return only 5 words, if true will return all posible trustwords for both identities.
    ///    - completion returns the result if available, returns nil otherwize
    /// For example absense of fingerprints, or a failure in the session. If so will be nil.
    func getTrustwords(for SelfIdentity: Identity,
                       and partnerIdentity: Identity,
                       language: String,
                       long: Bool,
                       completion: @escaping (String?) -> Void)

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
    ///
    /// - Parameter partnerIdentity: Identity in which the action will be taken.
    ///   - completion: Success completion block
    ///   - errorCallback: Error callback
    func resetTrust(for partnerIdentity: Identity?,
                    completion: @escaping () -> (),
                    errorCallback: (() -> Void)?)

    /// Calls the completion block with a list of available languages codes
    /// in ISO 639-1 for the self identity
    ///
    /// - Parameters:
    ///   - acceptedLanguages: The list of the accepted languages codes.
    ///   Nil if don't want any filter at all.
    ///   For example: ["de", "en"] for german and english.
    ///   This list will be used to filter the languages retrieved by the engine.
    ///
    ///   - completion: The completion block
    func languagesList(acceptedLanguages: [String]?, completion: @escaping ([String]) -> ())

    func getFingerprint(for identity: Identity,
                        completion: @escaping (String?) -> ())

    /// - Parameter message: The message to generate the handshake combinations.
    /// - returns: The possible handshake combinations.
    func handshakeCombinations(message: Message,
                               shouldAllowHandshakeActions: Bool,
                               completion: @escaping ([TrustManagementUtil.HandshakeCombination]) -> Void)

    /// - Parameter identities: The identities to generate the handshake combinations
    /// - returns: The possible handshake combinations.
    func handshakeCombinations(identities: [Identity],
                               shouldAllowHandshakeActions: Bool,
                               completion: @escaping ([TrustManagementUtil.HandshakeCombination]) -> Void)
}
