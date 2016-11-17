// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CdMessage.swift instead.

import CoreData

import MessageModel

open class _CdMessage: NSManagedObject {

    // MARK: - Properties

    @NSManaged open
    var flagAnswered: NSNumber

    @NSManaged open
    var flagDeleted: NSNumber
 
    @NSManaged open
    var flagDraft: NSNumber

    @NSManaged open
    var flagFlagged: NSNumber

    @NSManaged open
    var flagRecent: NSNumber

    @NSManaged open
    var flagSeen: NSNumber

    @NSManaged open
    var flags: NSNumber

    @NSManaged open
    var flagsFromServer: NSNumber

    @NSManaged open
    var longMessage: String?

    @NSManaged open
    var longMessageFormatted: String?

    @NSManaged open
    var messageID: String?

    @NSManaged open
    var pepColorRating: NSNumber?
 
    @NSManaged open
    var receivedDate: NSDate?

    @NSManaged open
    var subject: String?

    @NSManaged open
    var uid: NSNumber

    // MARK: - Relationships

    @NSManaged open
    var attachments: NSOrderedSet

    /* XXX: If needed, to be transferred to new CdMessage.
    open func attachmentsSet() -> NSMutableOrderedSet {
        return self.attachments.mutableCopy() as! NSMutableOrderedSet
    }
    */

    @NSManaged open
    var bcc: NSOrderedSet

    @NSManaged open
    var cc: NSOrderedSet

    @NSManaged open
    var folder: CdFolder

    @NSManaged open
    var from: CdIdentity?

    @NSManaged open
    var references: NSOrderedSet

    @NSManaged open
    var to: NSOrderedSet
}

extension _CdMessage {

    open func addAttachmentsObject(value: CdAttachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }
    
    /* XXX: To be transferred to new CdMessage.
    open func addAttachments(objects: NSOrderedSet) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    open func removeAttachments(objects: NSOrderedSet) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    open func removeAttachmentsObject(value: CdAttachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }
    */
}
