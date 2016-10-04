// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Message.swift instead.

import Foundation
import CoreData

public enum MessageAttributes: String {
    case bodyFetched = "bodyFetched"
    case boundary = "boundary"
    case contentType = "contentType"
    case flagAnswered = "flagAnswered"
    case flagDeleted = "flagDeleted"
    case flagDraft = "flagDraft"
    case flagFlagged = "flagFlagged"
    case flagRecent = "flagRecent"
    case flagSeen = "flagSeen"
    case flags = "flags"
    case flagsFromServer = "flagsFromServer"
    case longMessage = "longMessage"
    case longMessageFormatted = "longMessageFormatted"
    case messageID = "messageID"
    case messageNumber = "messageNumber"
    case pepColorRating = "pepColorRating"
    case receivedDate = "receivedDate"
    case subject = "subject"
    case uid = "uid"
}

public enum MessageRelationships: String {
    case attachments = "attachments"
    case bcc = "bcc"
    case cc = "cc"
    case folder = "folder"
    case from = "from"
    case messageReference = "messageReference"
    case references = "references"
    case to = "to"
}

open class _Message: BaseManagedObject {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Message"
    }

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Message.entity(managedObjectContext: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var bodyFetched: NSNumber?

    @NSManaged open
    var boundary: String?

    @NSManaged open
    var contentType: String?

    @NSManaged open
    var flagAnswered: NSNumber?

    @NSManaged open
    var flagDeleted: NSNumber?

    @NSManaged open
    var flagDraft: NSNumber?

    @NSManaged open
    var flagFlagged: NSNumber?

    @NSManaged open
    var flagRecent: NSNumber?

    @NSManaged open
    var flagSeen: NSNumber?

    @NSManaged open
    var flags: NSNumber?

    @NSManaged open
    var flagsFromServer: NSNumber?

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
    var uid: NSNumber?

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
    var folder: Folder

    @NSManaged open
    var from: Contact?

    @NSManaged open
    var messageReference: MessageReference?

    @NSManaged open
    var references: NSOrderedSet

    open func referencesSet() -> NSMutableOrderedSet {
        return self.references.mutableCopy() as! NSMutableOrderedSet
    }

    @NSManaged open
    var to: NSOrderedSet

    open func toSet() -> NSMutableOrderedSet {
        return self.to.mutableCopy() as! NSMutableOrderedSet
    }

}

extension _Message {

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

    open func addAttachmentsObject(value: Attachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    open func removeAttachmentsObject(value: Attachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

}

extension _Message {

    open func addBcc(objects: NSOrderedSet) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    open func removeBcc(objects: NSOrderedSet) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    open func addBccObject(value: Contact) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    open func removeBccObject(value: Contact) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

}

extension _Message {

    open func addCc(objects: NSOrderedSet) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    open func removeCc(objects: NSOrderedSet) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    open func addCcObject(value: Contact) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    open func removeCcObject(value: Contact) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.cc = mutable.copy() as! NSOrderedSet
    }

}

extension _Message {

    open func addReferences(objects: NSOrderedSet) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.references = mutable.copy() as! NSOrderedSet
    }

    open func removeReferences(objects: NSOrderedSet) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.references = mutable.copy() as! NSOrderedSet
    }

    open func addReferencesObject(value: MessageReference) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.references = mutable.copy() as! NSOrderedSet
    }

    open func removeReferencesObject(value: MessageReference) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.references = mutable.copy() as! NSOrderedSet
    }

}

extension _Message {

    open func addTo(objects: NSOrderedSet) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.to = mutable.copy() as! NSOrderedSet
    }

    open func removeTo(objects: NSOrderedSet) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.to = mutable.copy() as! NSOrderedSet
    }

    open func addToObject(value: Contact) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.to = mutable.copy() as! NSOrderedSet
    }

    open func removeToObject(value: Contact) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.to = mutable.copy() as! NSOrderedSet
    }

}

