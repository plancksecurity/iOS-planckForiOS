// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MessageContent.swift instead.

import Foundation
import CoreData

public enum MessageContentAttributes: String {
    case data = "data"
}

public enum MessageContentRelationships: String {
    case message = "message"
}

public protocol IMessageContent {

    // MARK: - Properties

    var data: NSData { get set }

    // MARK: - Relationships

    var message: Message? { get set }

}

public class _MessageContent: BaseManagedObject, IMessageContent {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "MessageContent"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _MessageContent.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var data: NSData

    // MARK: - Relationships

    @NSManaged public
    var message: Message?

}

