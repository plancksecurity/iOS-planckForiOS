//
//  CdMessage+Extensions.swift
//  MessageModel
//
//  Created by Andreas Buff on 14.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

extension CdMessage {
    typealias Uid = Int32
}

// MARK: - Validation

extension CdMessage {

    //!!!: If we go for seperating incoming and outgoing message, only createOutgoingMessage() is allowed to set a MessageId.
    public override func validateForInsert() throws {
        if uuid == nil {
            uuid = MessageID.generateUUID()
        }
        try super.validateForInsert()
    }
}

extension CdMessage {
    //!!!: rename in DB
    var messageID: String? {
        return uuid
    }

    /// Calls:
    /// search(uid: Uid?, uuid theUuid: String?, folderName folder: String?,
    ///                                         inAccount account: CdAccount) -> CdMessage?
    ///
    /// - Parameter message: message to search for
    /// - Returns: existing message if found, nil otherwize
    static func search(message: Message) -> CdMessage? {
        guard  let cdAccount = message.cdObject.parent?.account else {
            Log.shared.errorAndCrash("Account not found?")
            return nil
        }
        return search(uid: Int32(message.uid),
                      uuid: message.uuid,
                      folderName: message.parent.name,
                      inAccount: cdAccount,
                      context: message.session.moc)
    }

    /// Searches message by UID + UUID + foldername + parentFolder.account.
    /// - Parameter message: message to search for
    /// - Returns: existing message if found, nil otherwize
    static func search(uid: Uid?,
                              uuid: String,
                              folderName folder: String?,
                              inAccount account: CdAccount,
                              context: NSManagedObjectContext) -> CdMessage? {
        if let parentFolder = folder,
            let validUid = validateUid(uid: uid),
            let result = by(uid: validUid,
                            uuid: uuid,
                            folderName: parentFolder,
                            account: account,
                            context: context) {
            return result
        }
        return nil
    }

    /// Validates the UID has already been received.
    ///
    /// - Parameter uid: UID to validate
    /// - Returns: if valid: UID, nil otherwize
    static private func validateUid(uid: Uid?) -> Uid? {
        // uid == 0 means it has not been received yet
        return (uid != nil && uid != 0) ? uid : nil
    }

    /// Assures the `imap` and `imap.localFlags` are not nil
    func assureImapAndFlagsNotNil() {
        guard let context = managedObjectContext else {
            return
        }
        if imap?.localFlags == nil || imap?.serverFlags == nil {
            imap = imapFields(context: context)
        }
    }

    func replace(referenceStrings: [String], context: NSManagedObjectContext) {
        let refs = referenceStrings.map {
            addMessageReference(messageID: $0, referenceType: .reference, context: context)
        }
        references = NSOrderedSet(array: refs)
    }

    // MARK: - PRIVATE

    static private func by(uid: Int32,
                           uuid: MessageID,
                           folderName: String,
                           account: CdAccount,
                           context: NSManagedObjectContext) -> CdMessage? {
        let predicate =
            NSPredicate(format: "uid = %d AND uuid = %@ AND parent.name = %@ AND parent.account = %@",
                        uid,
                        uuid,
                        folderName,
                        account)
        guard
            let messages = CdMessage.all(predicate: predicate, in: context) as? [CdMessage]
            else {
                return nil
        }
        let msgsExistingOnServer = messages.filter { $0.uid > 0 }
        if msgsExistingOnServer.count > 1 {
            Log.shared.errorAndCrash("Multiple messages with UID %d in folder %@", uid, folderName)
        } else if messages.count > 1 {
            Log.shared.warn("Multiple messages with UID %d in folder %@", uid, folderName)
        }
        return messages.first
    }
}

//!!!: cleanup
/**
 Conversion to UI model
 */
extension CdMessage {
    @available(*, deprecated, message: "Use MessageModelObjectUtils.getMessage(fromCdMessage:)")
    func message() -> Message? {
        return MessageModelObjectUtils.getMessage(fromCdMessage: self)
    }

    func delete(context: NSManagedObjectContext) {
        context.delete(self)
        CdHeaderField.deleteOrphans(context: context)
    }
}

extension CdMessage {

    /// - Returns: The CdImapFields for this message, created newly if not existed previously.
    func imapFields(context: NSManagedObjectContext? = nil) -> CdImapFields {
        guard let moc = context ?? managedObjectContext else {
            Log.shared.errorAndCrash("No Context!")
            let mainContext: NSManagedObjectContext = Stack.shared.mainContext
            return imapFields(context: mainContext)
        }
        if let theImap = imap {
            theImap.assureLocalFlagsNotNil(context: moc)
            theImap.assureServerFlagsNotNil(context: moc)
            return theImap
        } else {
            let theImap = CdImapFields(context: moc)
            theImap.assureLocalFlagsNotNil(context: moc)
            theImap.assureServerFlagsNotNil(context: moc)
            theImap.message = self
            imap = theImap
            return theImap
        }
    }
}
