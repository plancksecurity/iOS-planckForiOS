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

@objc public protocol _IAccount {

    // MARK: - Properties

    var accountType: NSNumber { get set }

    var email: String { get set }

    var folderSeparator: String? { get set }

    var imapServerName: String { get set }

    var imapServerPort: NSNumber { get set }

    var imapTransport: NSNumber { get set }

    var imapUsername: String? { get set }

    var nameOfTheUser: String { get set }

    var smtpServerName: String { get set }

    var smtpServerPort: NSNumber { get set }

    var smtpTransport: NSNumber { get set }

    var smtpUsername: String? { get set }

    // MARK: - Relationships

    var folders: NSSet { get set }

}

open class _Account: BaseManagedObject, _IAccount {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Account"
    }

    open class func entity(_ managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Account.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var accountType: NSNumber

    @NSManaged open
    var email: String

    @NSManaged open
    var folderSeparator: String?

    @NSManaged open
    var imapServerName: String

    @NSManaged open
    var imapServerPort: NSNumber

    @NSManaged open
    var imapTransport: NSNumber

    @NSManaged open
    var imapUsername: String?

    @NSManaged open
    var nameOfTheUser: String

    @NSManaged open
    var smtpServerName: String

    @NSManaged open
    var smtpServerPort: NSNumber

    @NSManaged open
    var smtpTransport: NSNumber

    @NSManaged open
    var smtpUsername: String?

    // MARK: - Relationships

    @NSManaged open
    var folders: NSSet

}

public extension _Account {

    func addFolders(_ objects: NSSet) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.folders = mutable.copy() as! NSSet
    }

    func removeFolders(_ objects: NSSet) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.folders = mutable.copy() as! NSSet
    }

    func addFoldersObject(_ value: Folder) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.folders = mutable.copy() as! NSSet
    }

    func removeFoldersObject(_ value: Folder) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.folders = mutable.copy() as! NSSet
    }

}

