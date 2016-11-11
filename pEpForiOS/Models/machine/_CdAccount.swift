// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CdAccount.swift instead.

import CoreData

import MessageModel

open class _CdAccount: BaseManagedObject {

    // MARK: - Class methods

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName, in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _CdAccount.entity(managedObjectContext: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

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

}

