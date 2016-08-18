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

public class _Account: BaseManagedObject, _IAccount {

    // MARK: - Class methods

    public class func entityName () -> String {
        return "Account"
    }

    public class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName(self.entityName(), inManagedObjectContext: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Account.entity(managedObjectContext) else { return nil }
        self.init(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged public
    var accountType: NSNumber

    @NSManaged public
    var email: String

    @NSManaged public
    var folderSeparator: String?

    @NSManaged public
    var imapServerName: String

    @NSManaged public
    var imapServerPort: NSNumber

    @NSManaged public
    var imapTransport: NSNumber

    @NSManaged public
    var imapUsername: String?

    @NSManaged public
    var nameOfTheUser: String

    @NSManaged public
    var smtpServerName: String

    @NSManaged public
    var smtpServerPort: NSNumber

    @NSManaged public
    var smtpTransport: NSNumber

    @NSManaged public
    var smtpUsername: String?

    // MARK: - Relationships

    @NSManaged public
    var folders: NSSet

}

public extension _Account {

    func addFolders(objects: NSSet) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.unionSet(objects as Set<NSObject>)
        self.folders = mutable.copy() as! NSSet
    }

    func removeFolders(objects: NSSet) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.minusSet(objects as Set<NSObject>)
        self.folders = mutable.copy() as! NSSet
    }

    func addFoldersObject(value: Folder) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.addObject(value)
        self.folders = mutable.copy() as! NSSet
    }

    func removeFoldersObject(value: Folder) {
        let mutable = self.folders.mutableCopy() as! NSMutableSet
        mutable.removeObject(value)
        self.folders = mutable.copy() as! NSSet
    }

}

