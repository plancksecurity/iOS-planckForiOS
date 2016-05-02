//
//  StorePrefetchedMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class StorePrefetchedMailOperation: BaseOperation {
    let comp = "StorePrefetchedMailOperation"
    let message: CWIMAPMessage
    let accountEmail: String

    init(grandOperator: IGrandOperator, accountEmail: String, message: CWIMAPMessage) {
        self.accountEmail = accountEmail
        self.message = message
        super.init(grandOperator: grandOperator)
    }

    override func main() {
        let model = grandOperator.backgroundModel()
        var addresses = message.recipients() as! [CWInternetAddress]
        if let from = message.from() {
            addresses.append(from)
        }
        let contacts = addContacts(addresses, model: model)
        insertOrUpdateMail(contacts, message: message, model: model)
        model.save()
        markAsFinished()
    }

    func insertOrUpdateMail(contacts: [String: IContact], message: CWIMAPMessage,
                    model: IModel) {
        var mail: IMessage! = model.existingMessage(message)

        var isFresh = false
        if mail == nil {
            mail = model.insertNewMessage()
            isFresh = true
        }

        if isFresh || mail.sentDate != message.receivedDate() {
            mail.sentDate = message.receivedDate()
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
                    grandOperator.setErrorForOperation(
                        self, error: Constants.errorCouldNotInsertOrUpdate(comp))
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
    }

    func addContacts(contacts: [CWInternetAddress],
                     model: IModel) -> [String: IContact] {
        var added: [String: IContact] = [:]
        for address in contacts {
            if let addr = model.insertOrUpdateContactEmail(address.address(),
                                                           name: address.personal()) {
                added[addr.email] = addr
            } else {
                Log.error(comp, error: Constants.errorCouldNotInsertOrUpdate(comp))
            }
        }
        return added
    }
}