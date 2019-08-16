//
//  PEPSessionMoc.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 09/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework

class PEPSessionMoc: NSObject, PEPSessionProtocol  {
    func decryptMessageDict(_ messageDict: NSMutableDictionary, flags: UnsafeMutablePointer<PEPDecryptFlags>?, rating: UnsafeMutablePointer<PEPRating>?, extraKeys: AutoreleasingUnsafeMutablePointer<NSArray?>?, status: UnsafeMutablePointer<PEPStatus>?) throws -> [String : Any] {
        return [:]
    }

    func decryptMessage(_ message: PEPMessage, flags: UnsafeMutablePointer<PEPDecryptFlags>?, rating: UnsafeMutablePointer<PEPRating>?, extraKeys: AutoreleasingUnsafeMutablePointer<NSArray?>?, status: UnsafeMutablePointer<PEPStatus>?) throws -> PEPMessage {
        return PEPMessage()
    }

    func reEvaluateMessageDict(_ messageDict: [String : Any], xKeyList: [String]?, rating: UnsafeMutablePointer<PEPRating>, status: UnsafeMutablePointer<PEPStatus>?) throws {
    }

    func reEvaluateMessage(_ message: PEPMessage, xKeyList: [String]?, rating: UnsafeMutablePointer<PEPRating>, status: UnsafeMutablePointer<PEPStatus>?) throws {
    }

    func encryptMessageDict(_ messageDict: [String : Any], extraKeys: [String]?, encFormat: PEPEncFormat, status: UnsafeMutablePointer<PEPStatus>?) throws -> [String : Any] {
        return [:]
    }

    func encryptMessage(_ message: PEPMessage, extraKeys: [String]?, encFormat: PEPEncFormat, status: UnsafeMutablePointer<PEPStatus>?) throws -> PEPMessage {
        return PEPMessage()
    }

    func encryptMessage(_ message: PEPMessage, extraKeys: [String]?, status: UnsafeMutablePointer<PEPStatus>?) throws -> PEPMessage {
        return PEPMessage()
    }

    func encryptMessageDict(_ messageDict: [String : Any], forSelf ownIdentity: PEPIdentity, extraKeys: [String]?, status: UnsafeMutablePointer<PEPStatus>?) throws -> [String : Any] {
        return [:]
    }

    func encryptMessage(_ message: PEPMessage, forSelf ownIdentity: PEPIdentity, extraKeys: [String]?, status: UnsafeMutablePointer<PEPStatus>?) throws -> PEPMessage {
        return PEPMessage()
    }

    func encryptMessageDict(_ messageDict: [String : Any], toFpr: String, encFormat: PEPEncFormat, flags: PEPDecryptFlags, status: UnsafeMutablePointer<PEPStatus>?) throws -> [String : Any] {
        return [:]
    }

    func encryptMessage(_ message: PEPMessage, toFpr: String, encFormat: PEPEncFormat, flags: PEPDecryptFlags, status: UnsafeMutablePointer<PEPStatus>?) throws -> PEPMessage {
        return PEPMessage()
    }

    func outgoingRating(for theMessage: PEPMessage) throws -> NSNumber {
        return 0
    }

    func outgoingRatingPreview(for theMessage: PEPMessage) throws -> NSNumber {
        return 0
    }

    func rating(for identity: PEPIdentity) throws -> NSNumber {
        return 0
    }

    func trustwords(forFingerprint fingerprint: String, languageID: String, shortened: Bool) throws -> [Any] {
        return []
    }

    func mySelf(_ identity: PEPIdentity) throws {
    }

    func update(_ identity: PEPIdentity) throws {
    }

    func trustPersonalKey(_ identity: PEPIdentity) throws {
    }

    func keyMistrusted(_ identity: PEPIdentity) throws {
    }

    func keyResetTrust(_ identity: PEPIdentity) throws {
    }

    func importKey(_ keydata: String) throws -> [PEPIdentity] {
        return []
    }

    func logTitle(_ title: String, entity: String, description: String?, comment: String?) throws {
    }

    func getLog() throws -> String {
        return String()
    }

    func getTrustwordsIdentity1(_ identity1: PEPIdentity, identity2: PEPIdentity, language: String?, full: Bool) throws -> String {
        return String()
    }

    func getTrustwordsFpr1(_ fpr1: String, fpr2: String, language: String?, full: Bool) throws -> String {
        return String()
    }

    func languageList() throws -> [PEPLanguage] {
        return [PEPLanguage(), PEPLanguage()]
    }

    func rating(from string: String) -> PEPRating {
        return .fullyAnonymous
    }

    func string(from rating: PEPRating) -> String {
        return String()
    }

    func isPEPUser(_ identity: PEPIdentity) throws -> NSNumber {
        return 0
    }

    func setOwnKey(_ identity: PEPIdentity, fingerprint: String) throws {
    }

    func configurePassiveModeEnabled(_ enabled: Bool) {
    }

    func setFlags(_ flags: PEPIdentityFlags, for identity: PEPIdentity) throws {
    }

    func deliver(_ result: PEPSyncHandshakeResult, identitiesSharing: [PEPIdentity]?) throws {
    }

    func trustOwnKeyIdentity(_ identity: PEPIdentity) throws {
    }

    func color(from rating: PEPRating) -> PEPColor {
        return .green
    }

    func keyReset(_ identity: PEPIdentity, fingerprint: String?) throws {
    }

    func leaveDeviceGroupError() throws {
    }

}
