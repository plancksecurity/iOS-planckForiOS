// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to RawMessageSource.swift instead.

import Foundation
import CoreData

public enum RawMessageSourceAttributes: String {
    case data = "data"
}

public enum RawMessageSourceRelationships: String {
    case message = "message"
}

public class _RawMessageSource: BaseManagedObject {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "RawMessageSource"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _RawMessageSource.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var data: NSData

    // MARK: - Relationships

    @NSManaged public
    var message: Message?

}

