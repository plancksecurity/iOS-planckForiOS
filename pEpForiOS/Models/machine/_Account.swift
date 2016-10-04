// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Account.swift instead.

import Foundation
import CoreData

public enum AccountAttributes: String {
    case accountType = "accountType"
    case email = "email"
    case folderSeparator = "folderSeparator"
    case imapServerName = "imapServerName"
    case imapServerPort = "imapServerPort"
    case imapTransport = "imapTransport"
    case imapUsername = "imapUsername"
    case nameOfTheUser = "nameOfTheUser"
    case smtpServerName = "smtpServerName"
    case smtpServerPort = "smtpServerPort"
    case smtpTransport = "smtpTransport"
    case smtpUsername = "smtpUsername"
}

public enum AccountRelationships: String {
    case folders = "folders"
}

open class _Account: BaseManagedObject {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Account"
    }

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Account.entity(managedObjectContext: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var accountType: NSNumber?

    @NSManaged open
    var email: String

    @NSManaged open
    var folderSeparator: String?

    @NSManaged open
    var imapServerName: String

    @NSManaged open
    var imapServerPort: NSNumber?

    @NSManaged open
    var imapTransport: NSNumber?

    @NSManaged open
    var imapUsername: String?

    @NSManaged open
    var nameOfTheUser: String

    @NSManaged open
    var smtpServerName: String

    @NSManaged open
    var smtpServerPort: NSNumber?

    @NSManaged open
    var smtpTransport: NSNumber?

    @NSManaged open
    var smtpUsername: String?

    // MARK: - Relationships

    @NSManaged open
    var folders: NSSet

    open func foldersSet() -> NSMutableSet {
        return self.folders.mutableCopy() as! NSMutableSet
    }

}

extension _Account {

    open func addFolders(objects: NSSet) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.folders = mutable.copy() as! NSSet
    }

    open func removeFolders(objects: NSSet) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.folders = mutable.copy() as! NSSet
    }

    open func addFoldersObject(value: Folder) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.folders = mutable.copy() as! NSSet
    }

    open func removeFoldersObject(value: Folder) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.folders = mutable.copy() as! NSSet
    }

}

