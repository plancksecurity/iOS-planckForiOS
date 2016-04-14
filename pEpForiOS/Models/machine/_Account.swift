// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Account.swift instead.

import Foundation
import CoreData

public enum AccountAttributes: String {
    case accountType = "accountType"
    case email = "email"
    case imapAuthMethod = "imapAuthMethod"
    case imapServerName = "imapServerName"
    case imapServerPort = "imapServerPort"
    case imapTransport = "imapTransport"
    case imapUsername = "imapUsername"
    case smtpAuthMethod = "smtpAuthMethod"
    case smtpServerName = "smtpServerName"
    case smtpServerPort = "smtpServerPort"
    case smtpTransport = "smtpTransport"
    case smtpUsername = "smtpUsername"
}

public enum AccountRelationships: String {
    case folders = "folders"
}

public class _Account: BaseManagedObject {

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
    var accountType: NSNumber?

    @NSManaged public
    var email: String

    @NSManaged public
    var imapAuthMethod: String

    @NSManaged public
    var imapServerName: String

    @NSManaged public
    var imapServerPort: NSNumber?

    @NSManaged public
    var imapTransport: NSNumber?

    @NSManaged public
    var imapUsername: String?

    @NSManaged public
    var smtpAuthMethod: String

    @NSManaged public
    var smtpServerName: String

    @NSManaged public
    var smtpServerPort: NSNumber?

    @NSManaged public
    var smtpTransport: NSNumber?

    @NSManaged public
    var smtpUsername: String?

    // MARK: - Relationships

    @NSManaged public
    var folders: NSSet

}

extension _Account {

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

