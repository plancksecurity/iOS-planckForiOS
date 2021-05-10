//
//  Account+Fetching.swift
//  pEp
//
//  Created by Andreas Buff on 18.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

extension Account {
    public struct Fetch {
        /// Get all accounts that are allowed to be manually trusted.
        ///
        /// - Returns: Array of accounts allowed to be manually trusted
        static public func allAccountsAllowedToManuallyTrust(session: Session = Session.main) -> [Account] {
            let allowedPredicate = CdServer.PredicateFactory.isAllowedToManuallyTrust()
            let allowedCdServers = CdServer.all(predicate: allowedPredicate,
                                                in: session.moc) as? [CdServer] ?? []
            var allowedAccounts = [Account]()
            for cdServer in allowedCdServers {
                guard let account = cdServer.account?.account() else {
                    Log.shared.errorAndCrash("No address")
                    continue
                }
                allowedAccounts.append(account)
            }
            return allowedAccounts
        }

        /// Get an account from an address
        ///
        /// - Parameter address: address to search account
        /// - Returns: account with parameter address. Nil if none account with that address
        ///   was found
        static public func accountAllowedToManuallyTrust(fromAddress address: String) -> Account? {
            let accounts = allAccountsAllowedToManuallyTrust()
            for account in accounts {
                if account.user.address == address {
                    return account
                }
            }
            return nil
        }
    }

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

    /// Returns all active Accouts in DB.
    /// To get also the inactive ones, pass false to the paramenter onlyActiveAccounts.
    ///
    /// - Parameters:
    ///   - onlyActiveAccounts: Indicates if the accounts to be retrieved must be active.
    ///   - session: Session to work with. Defaults to main session!
    /// - Returns: All (active) accounts in DB.
    public static func all(onlyActiveAccounts: Bool = true, in session: Session = Session.main) -> [Account] {
        if onlyActiveAccounts {
            let predicate = CdAccount.PredicateFactory.isActive()
            let cdAccounts = CdAccount.all(predicate: predicate, in: session.moc) as? [CdAccount] ?? []
            return cdAccounts.map { $0.account() }
        }
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
