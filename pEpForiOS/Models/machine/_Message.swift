// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Message.swift instead.

import Foundation
import CoreData

public enum MessageAttributes: String {
    case boundary = "boundary"
    case contentType = "contentType"
    case fetched = "fetched"
    case longMessage = "longMessage"
    case longMessageFormatted = "longMessageFormatted"
    case messageID = "messageID"
    case messageNumber = "messageNumber"
    case originationDate = "originationDate"
    case subject = "subject"
    case uid = "uid"
}

public enum MessageRelationships: String {
    case attachments = "attachments"
    case bcc = "bcc"
    case cc = "cc"
    case content = "content"
    case folder = "folder"
    case from = "from"
    case referenced = "referenced"
    case references = "references"
    case to = "to"
}

public protocol _IMessage {

    // MARK: - Properties

    var boundary: String? { get set }

    var contentType: String? { get set }

    var fetched: NSNumber { get set }

    var longMessage: String? { get set }

    var longMessageFormatted: String? { get set }

    var messageID: String? { get set }

    var messageNumber: NSNumber? { get set }

    var originationDate: NSDate? { get set }

    var subject: String? { get set }

    var uid: NSNumber? { get set }

    // MARK: - Relationships

    var attachments: NSOrderedSet { get set }

    var bcc: NSOrderedSet { get set }

    var cc: NSOrderedSet { get set }

    var content: MessageContent? { get set }

    var folder: Folder { get set }

    var from: Contact? { get set }

    var referenced: Message? { get set }

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
    var boundary: String?

    @NSManaged public
    var contentType: String?

    @NSManaged public
    var fetched: NSNumber

    @NSManaged public
    var longMessage: String?

    @NSManaged public
    var longMessageFormatted: String?

    @NSManaged public
    var messageID: String?

    @NSManaged public
    var messageNumber: NSNumber?

    @NSManaged public
    var originationDate: NSDate?

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
    var content: MessageContent?

    @NSManaged public
    var folder: Folder

    @NSManaged public
    var from: Contact?

    @NSManaged public
    var referenced: Message?

    @NSManaged public
    var references: NSOrderedSet

    @NSManaged public
    var to: NSOrderedSet

}

extension _Message {

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

extension _Message {

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

extension _Message {

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

extension _Message {

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

extension _Message {

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

