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

@objc public protocol _IFolder {

    // MARK: - Properties

    var existsCount: NSNumber { get set }

    var folderType: NSNumber { get set }

    var name: String { get set }

    var nextUID: NSNumber { get set }

    var shouldDelete: NSNumber { get set }

    var uidValidity: NSNumber? { get set }

    // MARK: - Relationships

    var account: Account { get set }

    var children: NSOrderedSet { get set }

    var messages: NSSet { get set }

    var parent: Folder? { get set }

}

open class _Folder: BaseManagedObject, _IFolder {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Folder"
    }

    open class func entity(_ managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Folder.entity(managedObjectContext) else { return nil }
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

    @NSManaged open
    var messages: NSSet

    @NSManaged open
    var parent: Folder?

}

public extension _Folder {

    func addChildren(_ objects: NSOrderedSet) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.union(objects)
        self.children = mutable.copy() as! NSOrderedSet
    }

    func removeChildren(_ objects: NSOrderedSet) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.minus(objects)
        self.children = mutable.copy() as! NSOrderedSet
    }

    func addChildrenObject(_ value: Folder) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.add(value)
        self.children = mutable.copy() as! NSOrderedSet
    }

    func removeChildrenObject(_ value: Folder) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.remove(value)
        self.children = mutable.copy() as! NSOrderedSet
    }

}

public extension _Folder {

    func addMessages(_ objects: NSSet) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.messages = mutable.copy() as! NSSet
    }

    func removeMessages(_ objects: NSSet) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.messages = mutable.copy() as! NSSet
    }

    func addMessagesObject(_ value: Message) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.messages = mutable.copy() as! NSSet
    }

    func removeMessagesObject(_ value: Message) {
        let mutable = self.messages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.messages = mutable.copy() as! NSSet
    }

}

