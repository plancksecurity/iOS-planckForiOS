//
//  FolderSyncService.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 21/11/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

protocol FolderSyncServiceDelegate: class {
    func finishedSyncingFolders()
}

class FolderSyncService: FolderSyncServiceProtocol, FetchImapFoldersServiceDelegate {
    weak var delegate : FolderSyncServiceDelegate?
    
    let parentName: String

    let fetchImapFoldersService = FetchImapFoldersService()

    var accountsToFetchFolders = 0
    var accountsFetched = 0
    
    init(parentName: String = #function) {
        self.parentName = parentName
    }

    private func requestFetchImapFoldersService(forAccounts accounts: [Account]) {
        fetchImapFoldersService.delegate = self
        accountsToFetchFolders = accounts.count
        for account in accounts {
            fetchImapFoldersService.fetchFolders(inAccount: account)
        }
    }
    
}

// MARK: - FolderSyncServiceProtocol

extension FolderSyncService {
    func requestFolders(inAccounts accounts: [Account]) {
        self.requestFetchImapFoldersService(forAccounts: accounts)
    }
}

// MARK: - FetchImapFoldersServiceDelegate
extension FolderSyncService {
    func finishedSyncingFolders(forAccount account: Account) {
        accountsFetched = accountsFetched + 1
        if accountsFetched == accountsToFetchFolders {
            delegate?.finishedSyncingFolders()
        }
    }
}
