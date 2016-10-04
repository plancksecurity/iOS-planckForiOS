// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MessageReference.swift instead.

import Foundation
import CoreData

public enum MessageReferenceAttributes: String {
    case messageID = "messageID"
}

public enum MessageReferenceRelationships: String {
    case message = "message"
    case referencingMessages = "referencingMessages"
}

@objc public protocol _IMessageReference {

    // MARK: - Properties

    var messageID: String { get set }

    // MARK: - Relationships

    var message: Message? { get set }

    var referencingMessages: NSSet { get set }

}

open class _MessageReference: BaseManagedObject, _IMessageReference {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "MessageReference"
    }

    open class func entity(_ managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _MessageReference.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var messageID: String

    // MARK: - Relationships

    @NSManaged open
    var message: Message?

    @NSManaged open
    var referencingMessages: NSSet

}

public extension _MessageReference {

    func addReferencingMessages(_ objects: NSSet) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    func removeReferencingMessages(_ objects: NSSet) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    func addReferencingMessagesObject(_ value: Message) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    func removeReferencingMessagesObject(_ value: Message) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.referencingMessages = mutable.copy() as! NSSet
    }

}

