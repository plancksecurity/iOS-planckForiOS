// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Folder.swift instead.

import Foundation
import CoreData

public enum FolderAttributes: String {
    case folderType = "folderType"
    case name = "name"
}

public enum FolderRelationships: String {
    case account = "account"
}

public class _Folder: BaseManagedObject {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "Folder"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Folder.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var folderType: NSNumber?

    @NSManaged public
    var name: String

    // MARK: - Relationships

    @NSManaged public
    var account: Account

}

