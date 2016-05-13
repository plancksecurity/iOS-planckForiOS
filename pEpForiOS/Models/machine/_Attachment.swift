// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Attachment.swift instead.

import Foundation
import CoreData

public enum AttachmentAttributes: String {
    case contentType = "contentType"
    case filename = "filename"
    case size = "size"
}

public enum AttachmentRelationships: String {
    case content = "content"
    case message = "message"
}

public protocol _IAttachment {

    // MARK: - Properties

    var contentType: String? { get set }

    var filename: String? { get set }

    var size: NSNumber? { get set }

    // MARK: - Relationships

    var content: AttachmentData { get set }

    var message: Message { get set }

}

public class _Attachment: BaseManagedObject, _IAttachment {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "Attachment"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Attachment.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var contentType: String?

    @NSManaged public
    var filename: String?

    @NSManaged public
    var size: NSNumber?

    // MARK: - Relationships

    @NSManaged public
    var content: AttachmentData

    @NSManaged public
    var message: Message

}

