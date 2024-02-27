//
//  Account+Fetching.swift
//  pEp
//
//  Created by Andreas Buff on 18.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

extension Account {

    //!!!: move in the "Fetch" struct above

    /// Finds Accounts whichs user owns the given address
    /// - note: The client is responsible for correct usage! defaults to main session!
    ///
    /// - Parameters:
    ///   - address: Address to search account for
    ///   - session: Session to work with. Defaults to main session!
    /// - Returns: the found Account if any, nil otherwize
    public static func by(address: String, in session: Session = Session.main) -> Account? {
        let moc = session.moc
        guard let cdAccount = CdAccount.by(address: address, context: moc) else {
            // Nothing found
            return nil
        }
        return MessageModelObjectUtils.getAccount(fromCdAccount: cdAccount)
    }

    /// Returns all Accouts in DB.
    ///
    /// - note: The client is responsible for correct usage! defaults to main session!
    ///
    /// - Parameters:
    ///   - session: Session to work with. Defaults to main session!
    /// - Returns: All accounts in DB.
    public static func all(in session: Session = Session.main) -> [Account] {
        let cdAccounts = CdAccount.all(in: session.moc) as? [CdAccount] ?? []
        return cdAccounts.map { $0.account() }
    }

    /// Finds Accounts whichs user owns the given address
    /// - note: The client is responsible for correct usage! defaults to main session!
    ///
    /// - Parameters:
    ///   - address: Address to search account for
    ///   - session: Session to work with. Defaults to main session!
    /// - Returns: the found Account if any, nil otherwize
    public func firstFolder(ofType: FolderType, in session: Session = Session.main) -> Folder? {
        let folders = cdObject.folders?.array.filter { (cdFolder) in
            guard let current = cdFolder as? CdFolder else {
                Log.shared.errorAndCrash("Error casting")
                return false
            }
            return current.folderTypeRawValue == ofType.rawValue
            } as? [CdFolder] ?? [CdFolder]()

        return folders.first?.folder()
    }

}
