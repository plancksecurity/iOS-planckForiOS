//
//  PEPSession+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 According to Swift, the parameters denoting a mail for encryption methods etc. are
 not just of the type `NSDictionary`, but this.
 - Note: If you move this to be inside of PEPSession, the debugger will have a hard time
 dealing with those. So I chose to rather pollute the namespace and have a working debugger.
 */
public typealias PEPMail = NSDictionary

/**
 Similar to `PEPMail`
 */
public typealias PEPContact = NSDictionary

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
    open let recipient: PEPContact
    open let recipientType: RecipientType

    open var description: String {
        return "\(recipient[kPepAddress]) (\(recipientType))"
    }

    public init(recipient: PEPContact, recipientType: RecipientType) {
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
    public typealias RecipientSortPredicate = (_ contact: PEPContact,
        _ session: PEPSession) -> Bool

    /**
     - Returns: True if a mail from `from` to `contact` would be encrypted.
     */
    public func isEncryptedPEPContact(_ contact: PEPContact,
                                      from: PEPContact) -> Bool {
        let color = outgoingColor(from: from as! [AnyHashable : Any],
                                  to: contact as! [AnyHashable : Any])
        return color.rawValue >= PEP_rating_reliable.rawValue
    }

    /**
     - Returns: False if a mail from `from` to `contact` would be encrypted.
     */
    public func isUnencryptedPEPContact(_ contact: PEPContact,
                                        from: PEPContact) -> Bool {
        return !isEncryptedPEPContact(contact, from: from)
    }

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
                if let c = contact as? PEPContact {
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
     Removes all unencrypted receivers and encrypted BCC receivers from a given PEP mail.
     - Parameter pepMail: The PEP mail
     - Returns: A 3-tuple consisting of all unencrypted receivers, all encrypted BCCs,
     and an encryptable PEP mail without all the "unencrypted receivers" and the encrypted BCCs.
     */
    public func filterOutSpecialReceiversForPEPMail(
        _ pepMail: PEPMail) -> (unencryptedReceivers: [PEPRecipient],
        encryptedBCC: [PEPRecipient], pepMailEncryptable: PEPMail) {
            let pepMailPurged = NSMutableDictionary.init(dictionary: pepMail)

            let session = PEPSession.init()

            let unencryptedPredicate: RecipientSortPredicate = { contact, session in
                return self.isUnencryptedPEPContact(
                    contact, from: pepMail[kPepFrom] as! PEPContact)
            }

            var unencrypted: [PEPRecipient] = []

            if let tos = pepMail[kPepTo] as? NSArray {
                let (unencryptedTo, encryptedTo) = filterOutUnencryptedReceivers(
                    tos, recipientType: RecipientType.to, session: session,
                    sortOutPredicate: unencryptedPredicate)
                pepMailPurged[kPepTo] = encryptedTo.map({$0.recipient}) as NSArray
                unencrypted.append(contentsOf: unencryptedTo)
            }

            if let ccs = pepMail[kPepCC] as? NSArray {
                let (unencryptedCC, encryptedCC) = filterOutUnencryptedReceivers(
                    ccs, recipientType: RecipientType.cc, session: session,
                    sortOutPredicate: unencryptedPredicate)
                pepMailPurged[kPepCC] = encryptedCC.map({$0.recipient}) as NSArray
                unencrypted.append(contentsOf: unencryptedCC)
            }

            var resultEncryptedBCC: [PEPRecipient] = []
            if let bccs = pepMail[kPepBCC] as? NSArray {
                let (unencryptedBCC, encryptedBCC) = filterOutUnencryptedReceivers(
                    bccs, recipientType: RecipientType.bcc, session: session,
                    sortOutPredicate: unencryptedPredicate)
                pepMailPurged[kPepBCC] = []
                unencrypted.append(contentsOf: unencryptedBCC)
                resultEncryptedBCC.append(contentsOf: encryptedBCC)
            }

            return (unencrypted, resultEncryptedBCC, pepMailPurged as PEPMail)
    }

    /**
     Checks whether a given PEP mail has any recipients.
     - Parameter pepMail: The PEP mail to check for recipients.
     - Returns: true if the mail has any recipients, false otherwise.
     */
    func pepMailHasRecipients(_ pepMail: PEPMail) -> Bool {
        let tos = pepMail[kPepTo] as? NSArray
        let ccs = pepMail[kPepCC] as? NSArray
        let bccs = pepMail[kPepBCC] as? NSArray
        return (tos != nil && tos!.count > 0) || (ccs != nil && ccs!.count > 0) ||
            (bccs != nil && bccs!.count > 0)
    }

    /**
     Sorts a given PEP mail into two buckets: One containing all encrypted mails
     that should be sent, and one for all unencrypted ones. The encrypted BCCs each get
     an email in the encrypted list. All contacts that can't be encrypted land in the
     unencrypted bucket.
     - Parameter pepMail: The PEP mail to put into encryption/non-encryption buckets
     - Returns: A tuple (encrypted, unencrypted) with the two buckets of mails.
     */
    public func bucketsForPEPMail(
        _ pepMail: PEPMail) -> (mailsToEncrypt: [PEPMail], mailsNotToEncrypt: [PEPMail]) {
        let (unencryptedReceivers, encryptedBCC, pepMailPurged) =
            filterOutSpecialReceiversForPEPMail(pepMail)

        var encryptedMails: [PEPMail] = []
        var unencryptedMails: [PEPMail] = []

        if pepMailHasRecipients(pepMailPurged) {
            encryptedMails.append(pepMailPurged)
        }

        if unencryptedReceivers.count > 0 {
            let unencryptedMail = NSMutableDictionary.init(dictionary: pepMailPurged)
            var tos: [PEPContact] = []
            var ccs: [PEPContact] = []
            var bccs: [PEPContact] = []
            for r in unencryptedReceivers {
                switch r.recipientType {
                case .to:
                    tos.append(r.recipient)
                case .cc:
                    ccs.append(r.recipient)
                    print("ccs: \(ccs)")
                case .bcc:
                    bccs.append(r.recipient)
                }
            }
            unencryptedMail[kPepTo] = tos
            unencryptedMail[kPepCC] = ccs
            unencryptedMail[kPepBCC] = bccs
            unencryptedMails.append(unencryptedMail as PEPMail)
        }

        for bcc in encryptedBCC {
            let mail = NSMutableDictionary.init(dictionary: pepMailPurged)
            mail[kPepTo] = []
            mail[kPepCC] = []
            mail[kPepBCC] = [bcc.recipient]
            encryptedMails.append(mail as PEPMail)
        }

        return (encryptedMails, unencryptedMails)
    }
}

/**
 Equatable for `PEPSession.PEPReceiver`.
 */
public func ==(lhs: PEPRecipient, rhs: PEPRecipient) -> Bool {
    return lhs.recipientType == rhs.recipientType &&
        (lhs.recipient as NSDictionary).isEqual(to: rhs.recipient as! [AnyHashable: Any])
}
