// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Attachment.swift instead.

import Foundation
import CoreData

public enum AttachmentAttributes: String {
    case contentType = "contentType"
    case data = "data"
    case filename = "filename"
    case size = "size"
}

public enum AttachmentRelationships: String {
    case message = "message"
}

@objc public protocol _IAttachment {

    // MARK: - Properties

    var contentType: String? { get set }

    var data: Data? { get set }

    var filename: String? { get set }

    var size: NSNumber { get set }

    // MARK: - Relationships

    var message: Message { get set }

}

open class _Attachment: BaseManagedObject, _IAttachment {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Attachment"
    }

    open class func entity(_ managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Attachment.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var contentType: String?

    @NSManaged open
    var data: Data?

    @NSManaged open
    var filename: String?

    @NSManaged open
    var size: NSNumber

    // MARK: - Relationships

    @NSManaged open
    var message: Message

}

