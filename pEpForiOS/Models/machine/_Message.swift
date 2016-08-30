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

    var receivedDate: NSDate? { get set }

    var subject: String? { get set }

    var uid: NSNumber? { get set }

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

public class _Message: BaseManagedObject, _IMessage {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "Message"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Message.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var bodyFetched: NSNumber

    @NSManaged public
    var boundary: String?

    @NSManaged public
    var contentType: String?

    @NSManaged public
    var flagAnswered: NSNumber

    @NSManaged public
    var flagDeleted: NSNumber

    @NSManaged public
    var flagDraft: NSNumber

    @NSManaged public
    var flagFlagged: NSNumber

    @NSManaged public
    var flagRecent: NSNumber

    @NSManaged public
    var flagSeen: NSNumber

    @NSManaged public
    var flags: NSNumber

    @NSManaged public
    var flagsFromServer: NSNumber

    @NSManaged public
    var longMessage: String?

    @NSManaged public
    var longMessageFormatted: String?

    @NSManaged public
    var messageID: String?

    @NSManaged public
    var messageNumber: NSNumber?

    @NSManaged public
    var pepColorRating: NSNumber?

    @NSManaged public
    var receivedDate: NSDate?

    @NSManaged public
    var subject: String?

    @NSManaged public
    var uid: NSNumber?

    // MARK: - Relationships

    @NSManaged public
    var attachments: NSOrderedSet

    @NSManaged public
    var bcc: NSOrderedSet

    @NSManaged public
    var cc: NSOrderedSet

    @NSManaged public
    var folder: Folder

    @NSManaged public
    var from: Contact?

    @NSManaged public
    var messageReference: MessageReference?

    @NSManaged public
    var references: NSOrderedSet

    @NSManaged public
    var to: NSOrderedSet

}

public extension _Message {

    func addAttachments(objects: NSOrderedSet) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.unionOrderedSet(objects)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    func removeAttachments(objects: NSOrderedSet) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.minusOrderedSet(objects)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    func addAttachmentsObject(value: Attachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.addObject(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

    func removeAttachmentsObject(value: Attachment) {
        let mutable = self.attachments.mutableCopy() as! NSMutableOrderedSet
        mutable.removeObject(value)
        self.attachments = mutable.copy() as! NSOrderedSet
    }

}

public extension _Message {

    func addBcc(objects: NSOrderedSet) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.unionOrderedSet(objects)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    func removeBcc(objects: NSOrderedSet) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.minusOrderedSet(objects)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    func addBccObject(value: Contact) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.addObject(value)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

    func removeBccObject(value: Contact) {
        let mutable = self.bcc.mutableCopy() as! NSMutableOrderedSet
        mutable.removeObject(value)
        self.bcc = mutable.copy() as! NSOrderedSet
    }

}

public extension _Message {

    func addCc(objects: NSOrderedSet) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.unionOrderedSet(objects)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    func removeCc(objects: NSOrderedSet) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.minusOrderedSet(objects)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    func addCcObject(value: Contact) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.addObject(value)
        self.cc = mutable.copy() as! NSOrderedSet
    }

    func removeCcObject(value: Contact) {
        let mutable = self.cc.mutableCopy() as! NSMutableOrderedSet
        mutable.removeObject(value)
        self.cc = mutable.copy() as! NSOrderedSet
    }

}

public extension _Message {

    func addReferences(objects: NSOrderedSet) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.unionOrderedSet(objects)
        self.references = mutable.copy() as! NSOrderedSet
    }

    func removeReferences(objects: NSOrderedSet) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.minusOrderedSet(objects)
        self.references = mutable.copy() as! NSOrderedSet
    }

    func addReferencesObject(value: MessageReference) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.addObject(value)
        self.references = mutable.copy() as! NSOrderedSet
    }

    func removeReferencesObject(value: MessageReference) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.removeObject(value)
        self.references = mutable.copy() as! NSOrderedSet
    }

}

public extension _Message {

    func addTo(objects: NSOrderedSet) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.unionOrderedSet(objects)
        self.to = mutable.copy() as! NSOrderedSet
    }

    func removeTo(objects: NSOrderedSet) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.minusOrderedSet(objects)
        self.to = mutable.copy() as! NSOrderedSet
    }

    func addToObject(value: Contact) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.addObject(value)
        self.to = mutable.copy() as! NSOrderedSet
    }

    func removeToObject(value: Contact) {
        let mutable = self.to.mutableCopy() as! NSMutableOrderedSet
        mutable.removeObject(value)
        self.to = mutable.copy() as! NSOrderedSet
    }

}

