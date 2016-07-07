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
public typealias PEPMail = [NSObject : AnyObject]

/**
 Similar to `PEPMail`
 */
public typealias PEPContact = NSMutableDictionary

/**
 - Note: If you move this to be inside of PEPSession, the debugger will have a hard time
 dealing with those. So I chose to rather pollute the namespace and have a working debugger.
 */
public enum RecipientType: Int, Hashable {
    case To = 1
    case CC
    case BCC

    public var hashValue: Int {
        return rawValue
    }

    public static func fromRawValue(value: Int) -> RecipientType {
        switch value {
        case 1:
            return .To
        case 2:
            return .CC
        case 3:
            return .BCC
        default:
            return .To
        }
    }
}

/**
 A PEP contact bundled with its receiver type (like BCC or CC).
 - Note: If you move this to be inside of PEPSession, the debugger will have a hard time
 dealing with those. So I chose to rather pollute the namespace and have a working debugger.
 */
public class PEPRecipient: Hashable, Equatable, CustomStringConvertible {
    public let recipient: NSMutableDictionary
    public let recipientType: RecipientType

    public var description: String {
        return "\(recipient[kPepAddress]) (\(recipientType))"
    }

    public init(recipient: NSMutableDictionary, recipientType: RecipientType) {
        self.recipient = recipient
        self.recipientType = recipientType
    }

    public var hashValue: Int {
        return 31 &* recipient.hashValue &+ recipientType.hashValue
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
    public typealias RecipientSortPredicate = (contact: PEPContact,
        session: PEPSession) -> Bool

    public func isUnencryptedPEPContact(contact: PEPContact,
                                        from: PEPContact) -> Bool {
        let color = outgoingContactColor(contact, from: from)
        return color.rawValue < PEP_rating_reliable.rawValue
    }

    public func outgoingContactColor(contact: PEPContact,
                                     from: PEPContact) -> PEP_color {
        let fakeMail: NSMutableDictionary = [:]
        fakeMail[kPepFrom] = from
        fakeMail[kPepOutgoing] = true
        fakeMail[kPepTo] = [contact]
        fakeMail[kPepShortMessage] = "Subject"
        fakeMail[kPepLongMessage]  = "Body"
        let color = outgoingMessageColor(fakeMail)
        return color
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
        recipients: NSArray, recipientType: RecipientType, session: PEPSession,
        sortOutPredicate: RecipientSortPredicate)
        -> (unencryptedReceivers: [PEPRecipient], encryptedReceivers: [PEPRecipient]) {
            let unencryptedReceivers = NSMutableOrderedSet()
            let encryptedReceivers = NSMutableOrderedSet()

            for contact in recipients {
                if let c = contact as? NSMutableDictionary {
                    let receiver = PEPRecipient.init(recipient: c, recipientType: recipientType)
                    if sortOutPredicate(contact: c, session: session) {
                        unencryptedReceivers.addObject(receiver)
                    } else {
                        encryptedReceivers.addObject(receiver)
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
    public func filterOutSpecialReceiversForPEPMail(pepMail: PEPMail)
        -> (unencryptedReceivers: [PEPRecipient], encryptedBCC: [PEPRecipient],
        pepMailEncryptable: PEPMail) {
            let pepMailPurged = NSMutableDictionary.init(dictionary: pepMail)

            let session = PEPSession.init()

            let unencryptedPredicate: RecipientSortPredicate = { contact, session in
                return self.isUnencryptedPEPContact(
                    contact, from: pepMail[kPepFrom] as! NSMutableDictionary)
            }

            let (unencryptedTo, encryptedTo) = filterOutUnencryptedReceivers(
                pepMail[kPepTo] as! NSArray, recipientType: RecipientType.To, session: session,
                sortOutPredicate: unencryptedPredicate)
            pepMailPurged[kPepTo] = encryptedTo.map({$0.recipient}) as NSArray

            let (unencryptedCC, encryptedCC) = filterOutUnencryptedReceivers(
                pepMail[kPepCC] as! NSArray, recipientType: RecipientType.CC, session: session,
                sortOutPredicate: unencryptedPredicate)
            pepMailPurged[kPepCC] = encryptedCC.map({$0.recipient}) as NSArray

            let (unencryptedBCC, encryptedBCC) = filterOutUnencryptedReceivers(
                pepMail[kPepBCC] as! NSArray, recipientType: RecipientType.BCC, session: session,
                sortOutPredicate: unencryptedPredicate)
            pepMailPurged[kPepBCC] = []

            var result = unencryptedTo
            result.appendContentsOf(unencryptedCC)
            result.appendContentsOf(unencryptedBCC)
            return (result, encryptedBCC, pepMailPurged as PEPMail)
    }

    /**
     Checks whether a given PEP mail has any recipients.
     - Parameter pepMail: The PEP mail to check for recipients.
     - Returns: true if the mail has any recipients, false otherwise.
     */
    func pepMailHasRecipients(pepMail: PEPMail) -> Bool {
        let tos = pepMail[kPepTo] as! NSArray
        let ccs = pepMail[kPepCC] as! NSArray
        let bccs = pepMail[kPepBCC] as! NSArray
        return tos.count > 0 || ccs.count > 0 || bccs.count > 0
    }

    /**
     Sorts a given PEP mail into two buckets: One containing all encrypted mails
     that should be sent, and one for all unencrypted ones.
     - Parameter pepMail: The PEP mail to put into encryption/non-encryption buckets
     - Returns: A tuple (encrypted, unencrypted) with the two buckets of mails.
     */
    public func bucketsForPEPMail(pepMail: PEPMail)
        -> (mailsToEncrypt: [PEPMail], mailsNotToEncrypt: [PEPMail]) {
            let (unencryptedReceivers, encryptedBCC, pepMailPurged) =
                filterOutSpecialReceiversForPEPMail(pepMail)

            var encryptedMails: [PEPMail] = []
            var unencryptedMails: [PEPMail] = []

            if pepMailHasRecipients(pepMailPurged) {
                encryptedMails.append(pepMailPurged)
            }

            let unencryptedMail = NSMutableDictionary.init(dictionary: pepMailPurged)
            var tos: [NSMutableDictionary] = []
            var ccs: [NSMutableDictionary] = []
            var bccs: [NSMutableDictionary] = []
            for r in unencryptedReceivers {
                switch r.recipientType {
                case .To:
                    tos.append(r.recipient)
                case .CC:
                    ccs.append(r.recipient)
                    print("ccs: \(ccs)")
                case .BCC:
                    bccs.append(r.recipient)
                }
            }
            unencryptedMail[kPepTo] = tos
            unencryptedMail[kPepCC] = ccs
            unencryptedMail[kPepBCC] = bccs
            unencryptedMails.append(unencryptedMail as PEPMail)

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
    return lhs.recipientType == rhs.recipientType && lhs.recipient == rhs.recipient
}