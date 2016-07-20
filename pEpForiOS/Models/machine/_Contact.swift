// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Contact.swift instead.

import Foundation
import CoreData

public enum ContactAttributes: String {
    case addressBookID = "addressBookID"
    case email = "email"
    case isMySelf = "isMySelf"
    case name = "name"
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

    // MARK: - Relationships

    var bccMessages: NSSet { get set }

    var ccMessages: NSSet { get set }

    var fromMessages: NSSet { get set }

    var toMessages: NSSet { get set }

}

public class _Contact: BaseManagedObject, _IContact {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "Contact"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Contact.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var addressBookID: NSNumber?

    @NSManaged public
    var email: String

    @NSManaged public
    var isMySelf: NSNumber

    @NSManaged public
    var name: String?

    // MARK: - Relationships

    @NSManaged public
    var bccMessages: NSSet

    @NSManaged public
    var ccMessages: NSSet

    @NSManaged public
    var fromMessages: NSSet

    @NSManaged public
    var toMessages: NSSet

}

public extension _Contact {

    func addBccMessages(objects: NSSet) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.unionSet(objects as Set<NSObject>)
        self.bccMessages = mutable.copy() as! NSSet
    }

    func removeBccMessages(objects: NSSet) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.minusSet(objects as Set<NSObject>)
        self.bccMessages = mutable.copy() as! NSSet
    }

    func addBccMessagesObject(value: Message) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.addObject(value)
        self.bccMessages = mutable.copy() as! NSSet
    }

    func removeBccMessagesObject(value: Message) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.removeObject(value)
        self.bccMessages = mutable.copy() as! NSSet
    }

}

public extension _Contact {

    func addCcMessages(objects: NSSet) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.unionSet(objects as Set<NSObject>)
        self.ccMessages = mutable.copy() as! NSSet
    }

    func removeCcMessages(objects: NSSet) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.minusSet(objects as Set<NSObject>)
        self.ccMessages = mutable.copy() as! NSSet
    }

    func addCcMessagesObject(value: Message) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.addObject(value)
        self.ccMessages = mutable.copy() as! NSSet
    }

    func removeCcMessagesObject(value: Message) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.removeObject(value)
        self.ccMessages = mutable.copy() as! NSSet
    }

}

public extension _Contact {

    func addFromMessages(objects: NSSet) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.unionSet(objects as Set<NSObject>)
        self.fromMessages = mutable.copy() as! NSSet
    }

    func removeFromMessages(objects: NSSet) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.minusSet(objects as Set<NSObject>)
        self.fromMessages = mutable.copy() as! NSSet
    }

    func addFromMessagesObject(value: Message) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.addObject(value)
        self.fromMessages = mutable.copy() as! NSSet
    }

    func removeFromMessagesObject(value: Message) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.removeObject(value)
        self.fromMessages = mutable.copy() as! NSSet
    }

}

public extension _Contact {

    func addToMessages(objects: NSSet) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.unionSet(objects as Set<NSObject>)
        self.toMessages = mutable.copy() as! NSSet
    }

    func removeToMessages(objects: NSSet) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.minusSet(objects as Set<NSObject>)
        self.toMessages = mutable.copy() as! NSSet
    }

    func addToMessagesObject(value: Message) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.addObject(value)
        self.toMessages = mutable.copy() as! NSSet
    }

    func removeToMessagesObject(value: Message) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.removeObject(value)
        self.toMessages = mutable.copy() as! NSSet
    }

}

