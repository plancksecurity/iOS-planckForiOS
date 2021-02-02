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

    private lazy var folderSyncService = FetchImapFoldersService()
    public var items: [FolderSectionViewModel]

    /// The hidden sections are the collapsed accounts.
    public var hiddenSections = Set<Int>()

    public func handleCollapsingSectionStateChanged(forAccountInSection section : Int, isCollapsed: Bool) {
        let address = items[section].userAddress
        AppSettings.shared.setAccountCollapsedState(address: address, isCollapsed: isCollapsed)
    }

    public var maxIndentationLevel: Int {
        return DeviceUtils.isIphone5 ? 3 : 4
    }

    public var shouldShowUnifiedFolders: Bool {
        return Account.countAllForUnified() > 1
    }

    public var folderForEmailListView: DisplayableFolderProtocol? {
        guard let folderSectionViewModel = items.first, folderSectionViewModel.count > 0 else {
            // No folders to show
            return nil
        }
        let first = folderSectionViewModel.firstInbox()
        return first.folder
    }

    public var shouldShowFolders: Bool {
        return shouldShowUnifiedFolders || folderForEmailListView != nil
    }

    public var folderToShow: DisplayableFolderProtocol {
        if shouldShowUnifiedFolders {
            return UnifiedInbox()
        }
        guard let folderToReturn = folderForEmailListView else {
            Log.shared.errorAndCrash("Folder not found")
            return self.folderToShow
        }
        return folderToReturn
    }

    public subscript(index: Int) -> FolderSectionViewModel {
        get {
            return self.items[index]
        }
    }

    public var count: Int {
        return items.count
    }

    /// Instantiates a folder hierarchy model with:
    /// One section per account
    /// One row per folder
    /// If no account is given, all accounts found in the store are taken into account.
    /// - Parameter accounts: accounts to to create folder hierarchy view model for.
    public init(withFoldersIn accounts: [Account]? = nil, isUnified: Bool = true) {
        items = [FolderSectionViewModel]()
        let accountsToUse: [Account]
        if let safeAccounts = accounts {
            accountsToUse = safeAccounts
        } else {
            accountsToUse = Account.all()
        }
        let includeInUnifiedFolders = isUnified && shouldShowUnifiedFolders
        generateSections(accounts: accountsToUse, includeInUnifiedFolders: includeInUnifiedFolders)

        for (index, item) in items.enumerated() {
            if item.isCollapsed {
                hiddenSections.insert(index)
            }
        }
    }

    /// Indicates if there isn't accounts registered.
    /// - Returns: True if there is no accounts.
    public func noAccountsExist() -> Bool {
        return Account.all().isEmpty
    }

    /// Refresh the folder list for all accounts.
    /// - Parameter completion: Callback that is executed when the task ends.
    public func refreshFolderList(completion: (()->())? = nil) {
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

    // MARK: - Private

    private func generateSections(accounts: [Account], includeInUnifiedFolders: Bool = true) {
        if includeInUnifiedFolders {
            items.append(FolderSectionViewModel(account: nil, unified: true))
        }
        for acc in accounts {
            items.append(FolderSectionViewModel(account: acc, unified: false))
        }
    }
}
