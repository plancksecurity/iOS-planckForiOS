import Foundation
import CoreData

@objc(Folder)
public class Folder: _Folder {
    let comp = "Folder"

    public static let CouldNotCreateFolder = 1000

    /**
     Inserts a folder of the given type.
     - Note: Caller is responsible for saving!
     */
    static func insertOrUpdateFolderWithName(folderName: String,
                                             folderType: Account.AccountType,
                                             accountEmail: String,
                                             context: NSManagedObjectContext) throws -> Folder? {
        let p = NSPredicate.init(format: "account.email = %@ and name = %@", accountEmail,
                                 folderName)
        if let folder = BaseManagedObject.singleEntityWithName(entityName(), predicate: p,
                                                               context: context) {
            return folder as? Folder
        }

        if let account = Account.byEmail(accountEmail, context: context) {
            let folder = NSEntityDescription.insertNewObjectForEntityForName(
                Folder.entityName(), inManagedObjectContext: context) as! Folder
            folder.account = account
            folder.name = folderName
            folder.folderType = folderType.rawValue
            return folder
        } else {
            let error = NSError.init(domain: comp, code: CouldNotCreateFolder,
                                     userInfo: [NSLocalizedDescriptionKey:
                                        NSLocalizedString("IMAP authentication failed",
                                            comment: "Error when testing IMAP account")])
            throw error
        }
    }
}
