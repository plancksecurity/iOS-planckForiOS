// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Folder.swift instead.

import Foundation
import CoreData

public enum FolderAttributes: String {
    case folderType = "folderType"
    case name = "name"
    case uidValidity = "uidValidity"
}

public enum FolderRelationships: String {
    case account = "account"
    case messages = "messages"
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

    @NSManaged public
    var uidValidity: NSNumber?

    // MARK: - Relationships

    @NSManaged public
    var account: Account

    @NSManaged public
    var messages: NSSet

}

extension _Folder {

    func addMessages(objects: NSSet) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.unionSet(objects as Set<NSObject>)
        self.messages = mutable.copy() as! NSSet
    }

    func removeMessages(objects: NSSet) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.minusSet(objects as Set<NSObject>)
        self.messages = mutable.copy() as! NSSet
    }

    func addMessagesObject(value: Message) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.addObject(value)
        self.messages = mutable.copy() as! NSSet
    }

    func removeMessagesObject(value: Message) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.removeObject(value)
        self.messages = mutable.copy() as! NSSet
    }

}

