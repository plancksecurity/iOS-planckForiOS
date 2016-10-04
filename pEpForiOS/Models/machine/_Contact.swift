// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Contact.swift instead.

import Foundation
import CoreData

public enum ContactAttributes: String {
    case addressBookID = "addressBookID"
    case email = "email"
    case isMySelf = "isMySelf"
    case name = "name"
    case pepUserID = "pepUserID"
}

public enum ContactRelationships: String {
    case bccMessages = "bccMessages"
    case ccMessages = "ccMessages"
    case fromMessages = "fromMessages"
    case toMessages = "toMessages"
}

@objc public protocol _IContact {

    // MARK: - Properties

    var addressBookID: NSNumber? { get set }

    var email: String { get set }

    var isMySelf: NSNumber { get set }

    var name: String? { get set }

    var pepUserID: String? { get set }

    // MARK: - Relationships

    var bccMessages: NSSet { get set }

    var ccMessages: NSSet { get set }

    var fromMessages: NSSet { get set }

    var toMessages: NSSet { get set }

}

open class _Contact: BaseManagedObject, _IContact {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Contact"
    }

    open class func entity(_ managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Contact.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var addressBookID: NSNumber?

    @NSManaged open
    var email: String

    @NSManaged open
    var isMySelf: NSNumber

    @NSManaged open
    var name: String?

    @NSManaged open
    var pepUserID: String?

    // MARK: - Relationships

    @NSManaged open
    var bccMessages: NSSet

    @NSManaged open
    var ccMessages: NSSet

    @NSManaged open
    var fromMessages: NSSet

    @NSManaged open
    var toMessages: NSSet

}

public extension _Contact {

    func addBccMessages(_ objects: NSSet) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.bccMessages = mutable.copy() as! NSSet
    }

    func removeBccMessages(_ objects: NSSet) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.bccMessages = mutable.copy() as! NSSet
    }

    func addBccMessagesObject(_ value: Message) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.bccMessages = mutable.copy() as! NSSet
    }

    func removeBccMessagesObject(_ value: Message) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.bccMessages = mutable.copy() as! NSSet
    }

}

public extension _Contact {

    func addCcMessages(_ objects: NSSet) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.ccMessages = mutable.copy() as! NSSet
    }

    func removeCcMessages(_ objects: NSSet) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.ccMessages = mutable.copy() as! NSSet
    }

    func addCcMessagesObject(_ value: Message) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.ccMessages = mutable.copy() as! NSSet
    }

    func removeCcMessagesObject(_ value: Message) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.ccMessages = mutable.copy() as! NSSet
    }

}

public extension _Contact {

    func addFromMessages(_ objects: NSSet) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.fromMessages = mutable.copy() as! NSSet
    }

    func removeFromMessages(_ objects: NSSet) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.fromMessages = mutable.copy() as! NSSet
    }

    func addFromMessagesObject(_ value: Message) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.fromMessages = mutable.copy() as! NSSet
    }

    func removeFromMessagesObject(_ value: Message) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.fromMessages = mutable.copy() as! NSSet
    }

}

public extension _Contact {

    func addToMessages(_ objects: NSSet) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.toMessages = mutable.copy() as! NSSet
    }

    func removeToMessages(_ objects: NSSet) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.toMessages = mutable.copy() as! NSSet
    }

    func addToMessagesObject(_ value: Message) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.toMessages = mutable.copy() as! NSSet
    }

    func removeToMessagesObject(_ value: Message) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.toMessages = mutable.copy() as! NSSet
    }

}

