// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CdAttachment.swift instead.

import Foundation
import CoreData

public enum CdAttachmentAttributes: String {
    case contentType = "contentType"
    case data = "data"
    case filename = "filename"
    case size = "size"
}

public enum CdAttachmentRelationships: String {
    case message = "message"
}

open class _CdAttachment: BaseManagedObject {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Attachment"
    }

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _CdAttachment.entity(managedObjectContext: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var contentType: String?

    @NSManaged open
    var data: NSData?

    @NSManaged open
    var filename: String?

    @NSManaged open
    var size: NSNumber

    // MARK: - Relationships

    @NSManaged open
    var message: Message

}

