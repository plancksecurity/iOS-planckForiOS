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
    let message: CWIMAPMessage
    let errorDomain = "StorePrefetchedMailOperation"
    let accountEmail: String

    init(grandOperator: GrandOperator, accountEmail: String, message: CWIMAPMessage) {
        self.accountEmail = accountEmail
        self.message = message
        super.init(grandOperator: grandOperator)
    }

    override func main() {
        let context = grandOperator.coreDataUtil.confinedManagedObjectContext()
        var addresses = message.recipients() as! [CWInternetAddress]
        addresses.append(message.from())
        let contacts = addContacts(addresses, context: context)
        insertOrUpdateMail(contacts, message: message, context: context)
        CoreDataUtil.saveContext(managedObjectContext: context)
    }

    func insertOrUpdateMail(contacts: [String: Contact], message: CWIMAPMessage,
                    context: NSManagedObjectContext) {
        var mail: Message! = Message.existingMessage(message, context: context)

        if mail == nil {
            mail = NSEntityDescription.insertNewObjectForEntityForName(
                Message.entityName(), inManagedObjectContext: context) as! Message
        }

        mail.subject = message.subject()
        mail.messageId = message.messageID()
        mail.uid = message.UID()
        do {
            if let folder = try Folder.insertOrUpdateFolderWithName(
                message.folder().name(), folderType: Account.AccountType.Imap,
                accountEmail: accountEmail, context: context) {
                mail.folder = folder
            }
        } catch let err as NSError {
            grandOperator.addError(err)
        }

        let ccs: NSMutableOrderedSet = []
        let tos: NSMutableOrderedSet = []
        for address in message.recipients() {
            let addr = address as! CWInternetAddress
            switch addr.type() {
            case PantomimeCcRecipient:
                ccs.addObject(contacts[addr.address()]!)
            case PantomimeToRecipient:
                tos.addObject(contacts[addr.address()]!)
            default:
                Log.warn(errorDomain, "Unsupported recipient type \(addr.type)")
            }
        }
        mail.cc = ccs
        mail.to = tos
        mail.from = contacts[message.from().address()]

        // TODO: Test references
        if let msgRefs = message.allReferences() {
            let references: NSMutableOrderedSet = []
            for ref in msgRefs {
                let stringRef = ref as! String
                let predicate = NSPredicate.init(format: "messageId = %@", stringRef)
                if let refMsg = BaseManagedObject.singleEntityWithName(Message.entityName(),
                                                                     predicate: predicate, context: context) {
                    references.addObject(refMsg)
                }
            }
        }
    }

    func updateContact(contact: Contact, address: CWInternetAddress) {
        contact.email = address.address()
        contact.name = address.personal()
    }

    func addContacts(contacts: [CWInternetAddress],
                     context: NSManagedObjectContext) -> [String: Contact] {
        var added: [String: Contact] = [:]
        for address in contacts {
            let fetch = NSFetchRequest.init(entityName:Contact.entityName())
            fetch.predicate = NSPredicate.init(format: "email == %@", address.address())
            do {
                let existing = try context.executeFetchRequest(fetch) as! [Contact]
                if existing.count > 1 {
                    Log.warn(errorDomain, "Duplicate contacts with address \(address.address())")
                    updateContact(existing[0], address: address)
                    added[existing[0].email] = existing[0]
                } else if existing.count == 1 {
                    updateContact(existing[0], address: address)
                    added[existing[0].email] = existing[0]
                } else {
                    let contact = NSEntityDescription.insertNewObjectForEntityForName(
                        Contact.entityName(), inManagedObjectContext: context) as! Contact
                    updateContact(contact, address: address)
                    added[contact.email] = contact
                }
            } catch let err as NSError {
                grandOperator.addError(err)
            }
        }
        return added
    }
}