// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Folder.swift instead.

import Foundation
import CoreData

public enum FolderAttributes: String {
    case existsCount = "existsCount"
    case folderType = "folderType"
    case name = "name"
    case nextUID = "nextUID"
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

    var uidValidity: NSNumber? { get set }

    // MARK: - Relationships

    var account: Account { get set }

    var children: NSOrderedSet { get set }

    var messages: NSSet { get set }

    var parent: Folder? { get set }

}

public class _Folder: BaseManagedObject, _IFolder {

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
    var existsCount: NSNumber

    @NSManaged public
    var folderType: NSNumber

    @NSManaged public
    var name: String

    @NSManaged public
    var nextUID: NSNumber

    @NSManaged public
    var uidValidity: NSNumber?

    // MARK: - Relationships

    @NSManaged public
    var account: Account

    @NSManaged public
    var children: NSOrderedSet

    @NSManaged public
    var messages: NSSet

    @NSManaged public
    var parent: Folder?

}

public extension _Folder {

    func addChildren(objects: NSOrderedSet) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.unionOrderedSet(objects)
        self.children = mutable.copy() as! NSOrderedSet
    }

    func removeChildren(objects: NSOrderedSet) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.minusOrderedSet(objects)
        self.children = mutable.copy() as! NSOrderedSet
    }

    func addChildrenObject(value: Folder) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.addObject(value)
        self.children = mutable.copy() as! NSOrderedSet
    }

    func removeChildrenObject(value: Folder) {
        let mutable = self.children.mutableCopy() as! NSMutableOrderedSet
        mutable.removeObject(value)
        self.children = mutable.copy() as! NSOrderedSet
    }

}

public extension _Folder {

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

