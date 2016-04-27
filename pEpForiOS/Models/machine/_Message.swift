// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Message.swift instead.

import Foundation
import CoreData

public enum MessageAttributes: String {
    case fetched = "fetched"
    case longMessage = "longMessage"
    case longMessageFormatted = "longMessageFormatted"
    case messageId = "messageId"
    case sentDate = "sentDate"
    case subject = "subject"
    case uid = "uid"
}

public enum MessageRelationships: String {
    case cc = "cc"
    case folder = "folder"
    case from = "from"
    case rawDataSource = "rawDataSource"
    case referenced = "referenced"
    case references = "references"
    case to = "to"
}

public class _Message: BaseManagedObject {

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
    var fetched: NSNumber?

    @NSManaged public
    var longMessage: String?

    @NSManaged public
    var longMessageFormatted: String?

    @NSManaged public
    var messageId: String?

    @NSManaged public
    var sentDate: NSDate?

    @NSManaged public
    var subject: String?

    @NSManaged public
    var uid: NSNumber?

    // MARK: - Relationships

    @NSManaged public
    var cc: NSOrderedSet

    @NSManaged public
    var folder: Folder

    @NSManaged public
    var from: Contact?

    @NSManaged public
    var rawDataSource: RawMessageSource?

    @NSManaged public
    var referenced: Message?

    @NSManaged public
    var references: NSOrderedSet

    @NSManaged public
    var to: NSOrderedSet

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

    func addReferencesObject(value: Message) {
        let mutable = self.references.mutableCopy() as! NSMutableOrderedSet
        mutable.addObject(value)
        self.references = mutable.copy() as! NSOrderedSet
    }

    func removeReferencesObject(value: Message) {
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

