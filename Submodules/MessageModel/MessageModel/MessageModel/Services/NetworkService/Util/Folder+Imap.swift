//
//  Folder+Imap.swift
//  pEp
//
//  Created by Andreas Buff on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

//!!!: move. Is not NetworkSevcice. Does look like interface

/// Logic based on data MessageModel should not know.
extension Folder {
    
    /// Whether or not the folder represents a remote folder
    var isSyncedWithServer: Bool {
        return cdObject.isSyncedWithServer
    }
}
