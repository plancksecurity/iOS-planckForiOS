// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to AttachmentData.swift instead.

import Foundation
import CoreData

public enum AttachmentDataAttributes: String {
    case data = "data"
    case size = "size"
}

public enum AttachmentDataRelationships: String {
    case attachment = "attachment"
}

public protocol _IAttachmentData {

    // MARK: - Properties

    var data: NSData { get set }

    var size: NSNumber { get set }

    // MARK: - Relationships

    var attachment: Attachment? { get set }

}

public class _AttachmentData: BaseManagedObject, _IAttachmentData {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "AttachmentData"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _AttachmentData.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var data: NSData

    @NSManaged public
    var size: NSNumber

    // MARK: - Relationships

    @NSManaged public
    var attachment: Attachment?

}

