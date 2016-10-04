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

@objc public protocol _IMessage {

    // MARK: - Properties

    var bodyFetched: NSNumber { get set }

    var boundary: String? { get set }

    var contentType: String? { get set }

    var flagAnswered: NSNumber { get set }

    var flagDeleted: NSNumber { get set }

    var flagDraft: NSNumber { get set }

    var flagFlagged: NSNumber { get set }

    var flagRecent: NSNumber { get set }

    var flagSeen: NSNumber { get set }

    var flags: NSNumber { get set }

    var flagsFromServer: NSNumber { get set }

    var longMessage: String? { get set }

    var longMessageFormatted: String? { get set }

    var messageID: String? { get set }

    var messageNumber: NSNumber? { get set }

    var pepColorRating: NSNumber? { get set }

    var receivedDate: Date? { get set }

    var subject: String? { get set }

    var uid: NSNumber { get set }

    // MARK: - Relationships

    var attachments: NSOrderedSet { get set }

    var bcc: NSOrderedSet { get set }

    var cc: NSOrderedSet { get set }

    var folder: Folder { get set }

    var from: Contact? { get set }

    var messageReference: MessageReference? { get set }

    var references: NSOrderedSet { get set }

    var to: NSOrderedSet { get set }

}

open class _Message: BaseManagedObject, _IMessage {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Message"
    }

    open class func entity(_ managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Message.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
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
    var receivedDate: Date?

    @NSManaged open
    var subject: String?

    @NSManaged open
    var uid: NSNumber

    // MARK: - Relationships

    @NSManaged open
    var attachments: NSOrderedSet

    @NSManaged open
    var bcc: NSOrderedSet

    @NSManaged open
    var cc: NSOrderedSet

    @NSManaged open
    var folder: Folder

    @NSManaged open
    var from: Contact?

    @NSManaged open
    var messageReference: MessageReference?

    @NSManaged open
    var references: NSOrderedSet

    @NSManaged open
    var to: NSOrderedSet

}

public extension _Message {

    func addAttachments(_ objects: NSOrderedSet) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    func removeAttachments(_ objects: NSOrderedSet) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    func addAttachmentsObject(_ value: Attachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    func removeAttachmentsObject(_ value: Attachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

}

public extension _Message {

    func addBcc(_ objects: NSOrderedSet) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    func removeBcc(_ objects: NSOrderedSet) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    func addBccObject(_ value: Contact) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    func removeBccObject(_ value: Contact) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

}

public extension _Message {

    func addCc(_ objects: NSOrderedSet) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    func removeCc(_ objects: NSOrderedSet) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    func addCcObject(_ value: Contact) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    func removeCcObject(_ value: Contact) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.cc = mutable.copy() as! NSOrderedSet
    }

}

public extension _Message {

    func addReferences(_ objects: NSOrderedSet) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.references = mutable.copy() as! NSOrderedSet
    }

    func removeReferences(_ objects: NSOrderedSet) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.references = mutable.copy() as! NSOrderedSet
    }

    func addReferencesObject(_ value: MessageReference) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.references = mutable.copy() as! NSOrderedSet
    }

    func removeReferencesObject(_ value: MessageReference) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.references = mutable.copy() as! NSOrderedSet
    }

}

public extension _Message {

    func addTo(_ objects: NSOrderedSet) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.to = mutable.copy() as! NSOrderedSet
    }

    func removeTo(_ objects: NSOrderedSet) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.to = mutable.copy() as! NSOrderedSet
    }

    func addToObject(_ value: Contact) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.to = mutable.copy() as! NSOrderedSet
    }

    func removeToObject(_ value: Contact) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.to = mutable.copy() as! NSOrderedSet
    }

}

