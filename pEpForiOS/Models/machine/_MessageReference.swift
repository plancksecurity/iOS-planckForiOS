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

public class _MessageReference: BaseManagedObject, _IMessageReference {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "MessageReference"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _MessageReference.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var messageID: String

    // MARK: - Relationships

    @NSManaged public
    var message: Message?

    @NSManaged public
    var referencingMessages: NSSet

}

public extension _MessageReference {

    func addReferencingMessages(objects: NSSet) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.unionSet(objects as Set<NSObject>)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    func removeReferencingMessages(objects: NSSet) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.minusSet(objects as Set<NSObject>)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    func addReferencingMessagesObject(value: Message) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.addObject(value)
        self.referencingMessages = mutable.copy() as! NSSet
    }

    func removeReferencingMessagesObject(value: Message) {
        let mutable = self.referencingMessages.mutableCopy() as! NSMutableSet
        mutable.removeObject(value)
        self.referencingMessages = mutable.copy() as! NSSet
    }

}

