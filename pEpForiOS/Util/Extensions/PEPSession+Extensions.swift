//
//  PEPSession+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

/**
 - Note: If you move this to be inside of PEPSession, the debugger will have a hard time
 dealing with those. So I chose to rather pollute the namespace and have a working debugger.
 */
public typealias PEPMessageDict = [String: AnyObject]

/**
 Similar to `PEPMessage`
 */
public typealias PEPIdentityDict = [String: AnyObject]

extension Dictionary where Key: ExpressibleByStringLiteral, Value: AnyObject {
    public func mutableDictionary() -> NSMutableDictionary {
        return NSMutableDictionary(dictionary: self)
    }
}

public func ==(lhs: PEPIdentityDict, rhs: PEPIdentityDict) -> Bool {
    let a = NSDictionary(dictionary: lhs)
    let b = NSDictionary(dictionary: rhs)
    return a == b
}

/**
 - Note: If you move this to be inside of PEPSession, the debugger will have a hard time
 dealing with those. So I chose to rather pollute the namespace and have a working debugger.
 */
public enum RecipientType: Int, Hashable {
    case to = 1
    case cc
    case bcc

    public var hashValue: Int {
        return rawValue
    }

    public static func fromRawValue(_ value: Int) -> RecipientType {
        switch value {
        case 1:
            return .to
        case 2:
            return .cc
        case 3:
            return .bcc
        default:
            return .to
        }
    }
}

/**
 A PEP contact bundled with its receiver type (like BCC or CC).
 */
open class PEPRecipient: Hashable, Equatable, CustomStringConvertible {
    open let recipient: PEPIdentityDict
    open let recipientType: RecipientType

    open var description: String {
        return "\(String(describing: recipient[kPepAddress])) (\(recipientType))"
    }

    public init(recipient: PEPIdentityDict, recipientType: RecipientType) {
        self.recipient = recipient
        self.recipientType = recipientType
    }

    open var hashValue: Int {
        return 31 &* (recipient as NSDictionary).hashValue &+ recipientType.hashValue
    }
}

/**
 Useful extensions for PEPSession
 */
public extension PEPSession {
    public func encrypt(pEpMessageDict: PEPMessageDict,
                        encryptionFormat: PEP_enc_format = PEP_enc_PEP,
                        forSelf: PEPIdentity? = nil) throws -> (PEP_STATUS, NSDictionary?) {
        return try PEPUtil.encrypt(
            pEpMessageDict: pEpMessageDict, encryptionFormat: encryptionFormat,
            forSelf: forSelf, session: self)
    }

    public func encrypt(pEpMessage: PEPMessage,
                        forSelf: PEPIdentity? = nil) throws -> (PEP_STATUS, PEPMessage?) {
        return try PEPUtil.encrypt(
            pEpMessage: pEpMessage, forSelf: forSelf, session: self)
    }

    /**
     Calculates the outgoing message rating for a hypothetical mail.
     - Returns: The message rating, or PEPRatingUndefined in case of any error.
     */
    public func outgoingMessageRating(from: Identity, to: [Identity],
                                      cc: [Identity], bcc: [Identity]) -> PEPRating {
        let msg = PEPMessage()
        msg.direction = PEP_dir_outgoing
        msg.from = from.pEpIdentity()
        let mapper: (Identity) -> PEPIdentity = { ident in
            return ident.pEpIdentity()
        }
        msg.to = to.map(mapper)
        msg.cc = cc.map(mapper)
        msg.bcc = bcc.map(mapper)
        msg.shortMessage = "short"
        msg.longMessage = "long"
        do {
            return try outgoingRating(for: msg).pEpRating
        } catch let error as NSError {
            assertionFailure("\(error)")
            return PEPRatingUndefined
        }
    }
}

public func ==(lhs: PEPRecipient, rhs: PEPRecipient) -> Bool {
    return lhs.recipientType == rhs.recipientType &&
        lhs.recipient == rhs.recipient
}
