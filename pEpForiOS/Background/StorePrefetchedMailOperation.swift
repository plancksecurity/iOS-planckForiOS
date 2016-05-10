//
//  StorePrefetchedMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 This can be used in a queue, or directly called with ```main()```.
 */
public class StorePrefetchedMailOperation: BaseOperation {
    let comp = "StorePrefetchedMailOperation"
    let message: CWIMAPMessage
    let accountEmail: String

    public init(grandOperator: IGrandOperator, accountEmail: String, message: CWIMAPMessage) {
        self.accountEmail = accountEmail
        self.message = message
        super.init(grandOperator: grandOperator)
    }

    override public func main() {
        let model = NSThread.isMainThread() ? grandOperator.model : grandOperator.backgroundModel()
        var addresses = message.recipients() as! [CWInternetAddress]
        if let from = message.from() {
            addresses.append(from)
        }
        let contacts = addContacts(addresses, model: model)
        insertOrUpdateMail(contacts, message: message, model: model)
        model.save()
    }

    func folderFromModel(model: IModel) -> Folder? {
        guard let folderName = message.folder()?.name() else {
            grandOperator.setErrorForOperation(
                self, error: Constants.errorCannotStoreMailWithoutFolder(comp))
            return nil
        }

        guard let folder = model.folderByName(
            folderName, email: accountEmail, folderType: Account.AccountType.Imap) as? Folder
            else {
                grandOperator.setErrorForOperation(
                    self, error: Constants.errorFolderDoesNotExist(comp,
                        folderName: folderName))
                return nil
        }

        return folder
    }

    func insertOrUpdateMail(contacts: [String: IContact], message: CWIMAPMessage,
                    model: IModel) -> IMessage? {
        guard let folder = folderFromModel(model) else {
            return nil
        }

        var isFresh = false
        var theMail: IMessage? = model.existingMessage(message)
        if theMail == nil {
            theMail = model.insertNewMessage()
            isFresh = true
        }

        var mail = theMail!

        mail.folder = folder

        if isFresh || mail.originationDate != message.receivedDate() {
            mail.originationDate = message.receivedDate()
        }
        if isFresh || mail.subject != message.subject() {
            mail.subject = message.subject()
        }
        if isFresh || mail.messageID != message.messageID() {
            mail.messageID = message.messageID()
        }
        if isFresh || mail.uid != message.UID() {
            mail.uid = message.UID()
        }
        if isFresh || mail.messageNumber != message.messageNumber() {
            mail.messageNumber = message.messageNumber()
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
        // TODO: Do the angle brackets (<>) belong to the messageID?
        if let msgRefs = message.allReferences() {
            for refID in msgRefs {
                let ref = model.insertOrUpdateMessageReference(refID as! String)
                (mail as! Message).addReferencesObject(ref as! MessageReference)
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