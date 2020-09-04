//
//  FolderViewModel.swift
//  pEp
//
//  Created by Martin Brude on 01/09/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public protocol FolderViewModelDelegate: class {
    func update()
}

/// View Model for folder hierarchy.
public class FolderViewModel {
    private var accountQueryResults: AccountQueryResults!
    private lazy var folderSyncService = FetchImapFoldersService()

    public weak var delegate: FolderViewModelDelegate?
    public var items: [FolderSectionViewModel]

    /// The hidden sections are the collapsed accounts.
    public var hiddenSections = Set<Int>()

    public var maxIndentationLevel: Int {
        return DeviceUtils.isIphone5 ? 3 : 4
    }

    public var shouldShowUnifiedFolders: Bool {
        // Show the unified folders if at least 2 will be included.
        return allAccounts.filter { $0.isIncludedInUnifiedFolders }.count > 1
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

    private var allAccounts: [Account] {
        return accountQueryResults.all
    }

    /// Instantiates a folder hierarchy model with:
    /// One section per account
    /// One row per folder
    /// If no account is given, all accounts found in the store are taken into account.
    /// - Parameter accounts: accounts to to create folder hierarchy view model for.
    public init(withFoldersIn accounts: [Account]? = nil, isUnified: Bool = true) {
        items = [FolderSectionViewModel]()
        self.accountQueryResults = AccountQueryResults(rowDelegate: self)
        try? self.accountQueryResults.startMonitoring()
        let accountsToUse: [Account]
        if let safeAccounts = accounts {
            accountsToUse = safeAccounts
        } else {
            accountsToUse = allAccounts
        }
        let includeInUnifiedFolders = isUnified && shouldShowUnifiedFolders
        generateSections(accounts: accountsToUse, includeInUnifiedFolders: includeInUnifiedFolders)
    }

    /// Indicates if there isn't accounts registered.
    /// - Returns: True if there is no accounts.
    public func noAccountsExist() -> Bool {
        return accountQueryResults.count == 0
    }

    /// Refresh the folder list for all accounts.
    /// - Parameter completion: Callback that is executed when the task ends.
    public func refreshFolderList(completion: (()->())? = nil) {
        do {
            try folderSyncService.runService(inAccounts: allAccounts) { Success in
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

extension FolderViewModel : QueryResultsIndexPathRowDelegate {

    public func didMoveRow(from: IndexPath, to: IndexPath) {
        // Intentionally we do not trigger any action here to avoid freezing the app.
        Log.shared.info("Folder View Model did move row")
    }

    public func willChangeResults() {
        // Intentionally we do not trigger any action here to avoid freezing the app.
        Log.shared.info("Folder View Model will change results")
    }

    public func didChangeResults() {
        // Intentionally we do not trigger any action here to avoid freezing the app.
        Log.shared.info("Folder View Model did change results")
    }

    public func didInsertRow(indexPath: IndexPath) {
        update()
    }

    public func didUpdateRow(indexPath: IndexPath) {
        update()
    }

    public func didDeleteRow(indexPath: IndexPath) {
        update()
    }

    private func update() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.delegate?.update()
        }
    }
}
