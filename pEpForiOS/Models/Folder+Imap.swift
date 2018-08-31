//
//  Folder+Imap.swift
//  pEp
//
//  Created by Andreas Buff on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Logic based on data MessageModel should not know.
extension Folder {

    /// Whether or not the folder represents a remote folder
    var isSyncedWithServer: Bool {
        return folderType.isSyncedWithServer
    }

    /// True if not synced with server
    var isLocalFolder: Bool {
        return !isSyncedWithServer
    }

    static public func allRemoteFolders(inAccount account: Account) -> [Folder] {
        var result = [Folder]()
        guard let cdAcc = CdAccount.search(account: account) else {
            return result
        }
        let pInAccount = CdFolder.PredicateFactory.inAccount(cdAccount: cdAcc)
        let pIsRemote = CdFolder.PredicateFactory.isSyncedWithServer()
        let p = NSCompoundPredicate(andPredicateWithSubpredicates: [pInAccount, pIsRemote])
        guard let cdFolders = CdFolder.all(predicate: p) as? [CdFolder] else {
            Log.shared.errorAndCrash(component: #function, errorString: "Error casting")
            return result
        }
        result =
            cdFolders
                .map { $0.folder() }
                .filter { $0.isSyncedWithServer }
        return result
    }
}
