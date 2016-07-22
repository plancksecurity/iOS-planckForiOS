// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MessageReference.swift instead.

import Foundation
import CoreData

public enum MessageReferenceAttributes: String {
    case messageID = "messageID"
}

public enum MessageReferenceRelationships: String {
    case referencingMessage = "referencingMessage"
}

@objc public protocol _IMessageReference {

    // MARK: - Properties

    var messageID: String { get set }

    // MARK: - Relationships

    var referencingMessage: Message? { get set }

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
    var referencingMessage: Message?

}

