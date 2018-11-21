//
//  FolderSyncServiceProtocol.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 21/11/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

/**
 Folder sync related actions that can be requested by the UI.
 The purpose is to make network-related actions seem as fast as possible,
 even with accounts that have to be polled, while still letting the backend
 have full control over the scheduling.
 */
protocol FolderSyncServiceProtocol {
   
    func requestFolders(inAccounts accounts: [Account])
}
