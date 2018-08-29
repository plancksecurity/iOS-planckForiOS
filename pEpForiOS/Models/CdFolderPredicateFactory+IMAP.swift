//
//  CdFolderPredicateFactory+IMAP.swift
//  pEp
//
//  Created by Andreas Buff on 29.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdFolder.PredicateFactory {

    static public  func isSyncedWithServer() -> NSPredicate {
        return NSPredicate(format: "folderTypeRawValue IN %@",
                           FolderType.typesSyncedWithImapServerRawValues)
    }
}
