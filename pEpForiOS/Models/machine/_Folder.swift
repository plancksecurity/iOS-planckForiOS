// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Folder.swift instead.

import Foundation
import CoreData

public enum FolderAttributes: String {
    case existsCount = "existsCount"
    case folderType = "folderType"
    case name = "name"
    case nextUID = "nextUID"
    case shouldDelete = "shouldDelete"
    case uidValidity = "uidValidity"
}

public enum FolderRelationships: String {
    case account = "account"
    case children = "children"
    case messages = "messages"
    case parent = "parent"
}

open class _Folder: BaseManagedObject {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Folder"
    }

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Folder.entity(managedObjectContext: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var existsCount: NSNumber

    @NSManaged open
    var folderType: NSNumber

    @NSManaged open
    var name: String

    @NSManaged open
    var nextUID: NSNumber

    @NSManaged open
    var shouldDelete: NSNumber

    @NSManaged open
    var uidValidity: NSNumber?

    // MARK: - Relationships

    @NSManaged open
    var account: Account

    @NSManaged open
    var children: NSOrderedSet

    open func childrenSet() -> NSMutableOrderedSet {
        return self.children.mutableCopy() as! NSMutableOrderedSet
    }

    @NSManaged open
    var messages: NSSet

    open func messagesSet() -> NSMutableSet {
        return self.messages.mutableCopy() as! NSMutableSet
    }

    @NSManaged open
    var parent: Folder?

}

extension _Folder {

    open func addChildren(objects: NSOrderedSet) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.children = mutable.copy() as! NSOrderedSet
    }

    open func removeChildren(objects: NSOrderedSet) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.children = mutable.copy() as! NSOrderedSet
    }

    open func addChildrenObject(value: Folder) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.children = mutable.copy() as! NSOrderedSet
    }

    open func removeChildrenObject(value: Folder) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.children = mutable.copy() as! NSOrderedSet
    }

}

extension _Folder {

    open func addMessages(objects: NSSet) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.messages = mutable.copy() as! NSSet
    }

    open func removeMessages(objects: NSSet) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.messages = mutable.copy() as! NSSet
    }

    open func addMessagesObject(value: Message) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.messages = mutable.copy() as! NSSet
    }

    open func removeMessagesObject(value: Message) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.messages = mutable.copy() as! NSSet
    }

}

