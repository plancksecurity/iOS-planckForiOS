//
//  FolderViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 21/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

/// View Model for folder hierarchy.
public class FolderViewModel {

    lazy var folderSyncService = FetchImapFoldersService()
    var items: [FolderSectionViewModel]

    /// Instantiates a folder hierarchy model with:
    /// One section per account
    /// One row per folder
    /// If no account is given, all accounts found in the store are taken into account.
    /// - Parameter accounts: accounts to to create folder hierarchy view model for.
    public init(withFoldersIn accounts: [Account]? = nil, includeUnifiedInbox: Bool = true) {
        items = [FolderSectionViewModel]()
        let accountsToUse: [Account]
        if let safeAccounts = accounts {
            accountsToUse = safeAccounts
        } else {
            accountsToUse = Account.all()
        }
        generateSections(accounts: accountsToUse, includeUnifiedInbox: includeUnifiedInbox)
    }

    private func generateSections(accounts: [Account], includeUnifiedInbox: Bool = true) {
        if includeUnifiedInbox {
            items.append(FolderSectionViewModel(account: nil, Unified: true))
        }
        for acc in accounts {
            items.append(FolderSectionViewModel(account: acc, Unified: false))
        }
    }

    public func noAccountsExist() -> Bool {
        return Account.all().isEmpty
    }

    func refreshFolderList(completion: (()->())? = nil) {
        do {
            try folderSyncService.runService(inAccounts: Account.all()) { Success in
                completion?()
            }
        } catch {
            guard let er = error as? FetchImapFoldersService.FetchError else {
                Log.shared.errorAndCrash("Unexpected error")
                completion?()
                return
            }

            switch er {
            case .accountNotFound:
                Log.shared.errorAndCrash("Account not found")
                completion?()
            case .isFetching:
                //is Fetching do nothing
                break
            }
            completion?()
        }
    }

    subscript(index: Int) -> FolderSectionViewModel {
        get {
            return self.items[index]
        }
    }

    var count: Int {
        return self.items.count
    }
}
