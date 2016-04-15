import Foundation
import CoreData

@objc(Folder)
public class Folder: _Folder {

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
        let fetch = NSFetchRequest.init(entityName: Folder.entityName())
        fetch.predicate = p
        let folders = try context.executeFetchRequest(fetch)
        if folders.count > 1 {
            Log.warn(comp, "Duplicate foldername \(folderName) for \(accountEmail)")
        } else if folders.count == 1 {
            let folder: Folder = folders[0] as! Folder
            return folder
        } else {
            if let account = Account.byEmail(accountEmail, context: context) {
                let folder = NSEntityDescription.insertNewObjectForEntityForName(
                    Folder.entityName(), inManagedObjectContext: context) as! Folder
                folder.account = account
                folder.name = folderName
                folder.folderType = folderType.rawValue
                return folder
            }
        }
        return nil
    }
}
