// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CdMessage.swift instead.

import Foundation
import CoreData

import MessageModel

open class _CdMessage: BaseManagedObject {

    // MARK: - Class methods

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName, in: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var bodyFetched: NSNumber

    @NSManaged open
    var boundary: String?

    @NSManaged open
    var contentType: String?

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
    var messageNumber: NSNumber?

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

    open func attachmentsSet() -> NSMutableOrderedSet {
        return self.attachments.mutableCopy() as! NSMutableOrderedSet
    }

    @NSManaged open
    var bcc: NSOrderedSet

    open func bccSet() -> NSMutableOrderedSet {
        return self.bcc.mutableCopy() as! NSMutableOrderedSet
    }

    @NSManaged open
    var cc: NSOrderedSet

    open func ccSet() -> NSMutableOrderedSet {
        return self.cc.mutableCopy() as! NSMutableOrderedSet
    }

    @NSManaged open
    var folder: CdFolder

    @NSManaged open
    var from: CdIdentity?

    @NSManaged open
    var messageReference: CdMessageReference?

    @NSManaged open
    var references: NSOrderedSet

    @NSManaged open
    var to: NSOrderedSet
}

extension _CdMessage {

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

    open func addAttachmentsObject(value: CdAttachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    open func removeAttachmentsObject(value: CdAttachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

}
