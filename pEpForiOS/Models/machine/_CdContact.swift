// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CdContact.swift instead.

import Foundation
import CoreData

public enum CdContactAttributes: String {
    case addressBookID = "addressBookID"
    case email = "email"
    case isMySelf = "isMySelf"
    case name = "name"
    case pepUserID = "pepUserID"
}

public enum CdContactRelationships: String {
    case bccMessages = "bccMessages"
    case ccMessages = "ccMessages"
    case fromMessages = "fromMessages"
    case toMessages = "toMessages"
}

open class _CdContact: BaseManagedObject {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Contact"
    }

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _CdContact.entity(managedObjectContext: managedObjectContext) else { return nil }
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

    open func bccMessagesSet() -> NSMutableSet {
        return self.bccMessages.mutableCopy() as! NSMutableSet
    }

    @NSManaged open
    var ccMessages: NSSet

    open func ccMessagesSet() -> NSMutableSet {
        return self.ccMessages.mutableCopy() as! NSMutableSet
    }

    @NSManaged open
    var fromMessages: NSSet

    open func fromMessagesSet() -> NSMutableSet {
        return self.fromMessages.mutableCopy() as! NSMutableSet
    }

    @NSManaged open
    var toMessages: NSSet

    open func toMessagesSet() -> NSMutableSet {
        return self.toMessages.mutableCopy() as! NSMutableSet
    }

}

extension _CdContact {

    open func addBccMessages(objects: NSSet) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.bccMessages = mutable.copy() as! NSSet
    }

    open func removeBccMessages(objects: NSSet) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.bccMessages = mutable.copy() as! NSSet
    }

    open func addBccMessagesObject(value: CdMessage) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.bccMessages = mutable.copy() as! NSSet
    }

    open func removeBccMessagesObject(value: CdMessage) {
        let mutable = self.bccMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.bccMessages = mutable.copy() as! NSSet
    }

}

extension _CdContact {

    open func addCcMessages(objects: NSSet) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.ccMessages = mutable.copy() as! NSSet
    }

    open func removeCcMessages(objects: NSSet) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.ccMessages = mutable.copy() as! NSSet
    }

    open func addCcMessagesObject(value: CdMessage) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.ccMessages = mutable.copy() as! NSSet
    }

    open func removeCcMessagesObject(value: CdMessage) {
        let mutable = self.ccMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.ccMessages = mutable.copy() as! NSSet
    }

}

extension _CdContact {

    open func addFromMessages(objects: NSSet) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.fromMessages = mutable.copy() as! NSSet
    }

    open func removeFromMessages(objects: NSSet) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.fromMessages = mutable.copy() as! NSSet
    }

    open func addFromMessagesObject(value: CdMessage) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.fromMessages = mutable.copy() as! NSSet
    }

    open func removeFromMessagesObject(value: CdMessage) {
        let mutable = self.fromMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.fromMessages = mutable.copy() as! NSSet
    }

}

extension _CdContact {

    open func addToMessages(objects: NSSet) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.toMessages = mutable.copy() as! NSSet
    }

    open func removeToMessages(objects: NSSet) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.toMessages = mutable.copy() as! NSSet
    }

    open func addToMessagesObject(value: CdMessage) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.toMessages = mutable.copy() as! NSSet
    }

    open func removeToMessagesObject(value: CdMessage) {
        let mutable = self.toMessages.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.toMessages = mutable.copy() as! NSSet
    }

}

