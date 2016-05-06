//
//  PersistentEmailCache.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 An implementation of `EmailCache` that uses core data.
 */
class PersistentEmailCache: NSObject {
    let comp = "PersistentEmailCache"
    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    let grandOperator: IGrandOperator

    init(grandOperator: IGrandOperator, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.grandOperator = grandOperator
        self.connectInfo = connectInfo
        self.backgroundQueue = backgroundQueue
    }

    func saveMessage(message: CWIMAPMessage) {
        executeMessageSaving(message, accountEmail: connectInfo.email)
        /*
        let op = StorePrefetchedMailOperation.init(grandOperator: self.grandOperator,
                                                   accountEmail: connectInfo.email,
                                                   message: message as! CWIMAPMessage)
        backgroundQueue.addOperation(op)
         */
    }

    func executeMessageSaving(message: CWIMAPMessage, accountEmail: String) {
        Log.info(comp, "storing \(message.UID()) in \(message.folder()?.name())")
        let model = grandOperator.model
        var addresses = message.recipients() as! [CWInternetAddress]
        if let from = message.from() {
            addresses.append(from)
        }
        let contacts = addContacts(addresses, model: model)
        let mail = insertOrUpdateMail(contacts, message: message, model: model,
                                      accountEmail: accountEmail)
        model.save()
        Log.info(comp, "stored \(mail.uid) in \(mail.folder.name) (\(mail.folder.messages.count))")
    }

    func insertOrUpdateMail(contacts: [String: IContact], message: CWIMAPMessage,
                            model: IModel, accountEmail: String) -> IMessage {
        var mail: IMessage! = model.existingMessage(message)

        var isFresh = false
        if mail == nil {
            mail = model.insertNewMessage()
            isFresh = true
        }

        if isFresh || mail.originationDate != message.receivedDate() {
            mail.originationDate = message.receivedDate()
        }
        if isFresh || mail.subject != message.subject() {
            mail.subject = message.subject()
        }
        if isFresh || mail.messageId != message.messageID() {
            mail.messageId = message.messageID()
        }
        if isFresh || mail.uid != message.UID() {
            mail.uid = message.UID()
        }
        if isFresh || mail.messageNumber != message.messageNumber() {
            mail.messageNumber = message.messageNumber()
        }

        if let folderName = message.folder()?.name() {
            if let folder = model.insertOrUpdateFolderName(
                folderName, folderType: Account.AccountType.Imap,
                accountEmail: accountEmail) {
                if isFresh || mail.folder.name != folder.name {
                    mail.folder = folder as! Folder
                }
            } else {
                // TODO: Signal error
            }
        }

        let ccs: NSMutableOrderedSet = []
        let tos: NSMutableOrderedSet = []
        for address in message.recipients() {
            let addr = address as! CWInternetAddress
            switch addr.type() {
            case PantomimeCcRecipient:
                ccs.addObject(contacts[addr.address()]! as! Contact)
            case PantomimeToRecipient:
                tos.addObject(contacts[addr.address()]! as! Contact)
            default:
                Log.warn(comp, "Unsupported recipient type \(addr.type)")
            }
        }
        if isFresh || mail.cc != ccs {
            mail.cc = ccs
        }
        if isFresh || mail.to != tos {
            mail.to = tos
        }
        if let from = message.from() {
            mail.from = contacts[from.address()] as? Contact
        }

        // TODO: Test references
        var messages = [IMessage]()
        if let msgRefs = message.allReferences() {
            var idSet = Set<String>()
            for ref in msgRefs {
                idSet.insert(ref as! String)
            }
            for ref in idSet {
                let predicate = NSPredicate.init(format: "messageId = %@", ref)
                if let refMsg = model.messageByPredicate(predicate) {
                    messages.append(refMsg)
                }
            }
        }
        return mail
    }

    func addContacts(contacts: [CWInternetAddress],
                     model: IModel) -> [String: IContact] {
        var added: [String: IContact] = [:]
        for address in contacts {
            if let addr = model.insertOrUpdateContactEmail(address.address(),
                                                           name: address.personal()) {
                added[addr.email] = addr
            } else {
                Log.error(comp, error: Constants.errorCouldNotUpdateOrAddContact(comp,
                    name: address.stringValue()))
            }
        }
        return added
    }
}

extension PersistentEmailCache: EmailCache {
    func invalidate() {
    }

    func synchronize() -> Bool {
        return true
    }

    func count() -> UInt {
        return 0
    }

    func removeMessageWithUID(theUID: UInt) {
    }

    func UIDValidity() -> UInt {
        return 0
    }

    func setUIDValidity(theUIDValidity: UInt) {
    }

    func messageWithUID(theUID: UInt) -> CWIMAPMessage! {
        let p = NSPredicate.init(format: "uid = %d", theUID)
        if let msg = grandOperator.model.messageByPredicate(p) {
            return msg.imapMessage()
        } else {
            Log.warn(comp, "Could not fetch message with uid \(theUID)")
            return nil
        }
    }

    func writeRecord(theRecord: CWCacheRecord!, message: CWIMAPMessage!) {
        saveMessage(message)
    }
}