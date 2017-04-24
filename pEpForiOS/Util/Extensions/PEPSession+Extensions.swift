//
//  PEPSession+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

/**
 - Note: If you move this to be inside of PEPSession, the debugger will have a hard time
 dealing with those. So I chose to rather pollute the namespace and have a working debugger.
 */
public typealias PEPMessage = [String: AnyObject]

/**
 Similar to `PEPMessage`
 */
public typealias PEPIdentity = [String: AnyObject]

public func ==(lhs: PEPIdentity, rhs: PEPIdentity) -> Bool {
    let a = NSDictionary.init(dictionary: lhs)
    let b = NSDictionary.init(dictionary: rhs)
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
 - Note: If you move this to be inside of PEPSession, the debugger will have a hard time
 dealing with those. So I chose to rather pollute the namespace and have a working debugger.
 */
open class PEPRecipient: Hashable, Equatable, CustomStringConvertible {
    open let recipient: PEPIdentity
    open let recipientType: RecipientType

    open var description: String {
        return "\(String(describing: recipient[kPepAddress])) (\(recipientType))"
    }

    public init(recipient: PEPIdentity, recipientType: RecipientType) {
        self.recipient = recipient
        self.recipientType = recipientType
    }

    open var hashValue: Int {
        return 31 &* (recipient as NSDictionary).hashValue &+ recipientType.hashValue
    }
}

/**
 Useful extensions for PEPSession, should move to the iOS Adapter if they prove usable
 across apps.
 */
public extension PEPSession {
    /**
     PEP predicate to run on a contact, given a session. Used for determining if a PEP contact
     matches some criteria.
     */
    public typealias RecipientSortPredicate = (_ contact: PEPIdentity,
        _ session: PEPSession) -> Bool

    /**
     Sorts the receivers from a pEp mail into a set of ordered an unordered recipients.
     - Parameter recipients: An `NSArray` of pEp contacts (`NSMutableDictionary`) taken
     directly from a pEp mail (e.g., `pEpMail[kPepTo]`)
     - Parameter recipientType: The recipient type the result should have (the method has to
     know which type of recipients it was given).
     - Parameter session: The pEp session.
     - Parameter sortOutPredicate: A closure that, given a pEp contact and a session, will
     return `true` if that recipient should be filtered out or `false` if not.
     - Returns: A tuple of the unencrypted recipients, and the encrypted recipients.
     Both elements are of type `NSOrderedSet` of `PEPRecipient`
     */
    func filterOutUnencryptedReceivers(
        _ recipients: NSArray, recipientType: RecipientType, session: PEPSession,
        sortOutPredicate: RecipientSortPredicate)
        -> (unencryptedReceivers: [PEPRecipient], encryptedReceivers: [PEPRecipient]) {
            let unencryptedReceivers = NSMutableOrderedSet()
            let encryptedReceivers = NSMutableOrderedSet()

            for contact in recipients {
                if let c = contact as? PEPIdentity {
                    let receiver = PEPRecipient.init(recipient: c, recipientType: recipientType)
                    if sortOutPredicate(c, session) {
                        unencryptedReceivers.add(receiver)
                    } else {
                        encryptedReceivers.add(receiver)
                    }
                }
            }

            return (unencryptedReceivers: unencryptedReceivers.array.map({$0 as! PEPRecipient}),
                    encryptedReceivers: encryptedReceivers.map({$0 as! PEPRecipient}))
    }

    /**
     Checks whether a given PEP mail has any recipients.
     - Parameter pepMail: The PEP mail to check for recipients.
     - Returns: true if the mail has any recipients, false otherwise.
     */
    func pepMailHasRecipients(_ pepMail: PEPMessage) -> Bool {
        let tos = pepMail[kPepTo] as? NSArray
        let ccs = pepMail[kPepCC] as? NSArray
        let bccs = pepMail[kPepBCC] as? NSArray
        return (tos != nil && tos!.count > 0) || (ccs != nil && ccs!.count > 0) ||
            (bccs != nil && bccs!.count > 0)
    }

    public func encrypt(pEpMessageDict: PEPMessage,
                        forIdentity: PEPIdentity? = nil) -> (PEP_STATUS, NSDictionary?) {
        return PEPUtil.encrypt(
            pEpMessageDict: pEpMessageDict, forIdentity: forIdentity, session: self)
    }
}

/**
 Equatable for `PEPSession.PEPReceiver`.
 */
public func ==(lhs: PEPRecipient, rhs: PEPRecipient) -> Bool {
    return lhs.recipientType == rhs.recipientType &&
        lhs.recipient == rhs.recipient
}
