// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CdMessageReference.swift instead.

import Foundation
import CoreData

public enum CdMessageReferenceAttributes: String {
    case messageID = "messageID"
}

public enum CdMessageReferenceRelationships: String {
    case message = "message"
    case referencingMessages = "referencingMessages"
}

open class _CdMessageReference: BaseManagedObject {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "MessageReference"
    }

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _CdMessageReference.entity(managedObjectContext: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var messageID: String

    // MARK: - Relationships

    @NSManaged open
    var message: CdMessage?

    @NSManaged open
    var referencingMessages: NSSet

    open func referencingMessagesSet() -> NSMutableSet {
        return self.referencingMessages.mutableCopy() as! NSMutableSet
    }

}

extension _CdMessageReference {

    open func addReferencingMessages(objects: NSSet) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    open func removeReferencingMessages(objects: NSSet) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    open func addReferencingMessagesObject(value: CdMessage) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    open func removeReferencingMessagesObject(value: CdMessage) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.referencingMessages = mutable.copy() as! NSSet
    }

}

