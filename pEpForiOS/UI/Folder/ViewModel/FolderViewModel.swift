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
    private let queryResultsDelegateHandlingQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.name = "FolderViewModel-queryResultsDelegateHandlingQueue"
        createe.qualityOfService = .userInteractive
        createe.maxConcurrentOperationCount = 1
        return createe
    }()
    private var accountQueryResults: AccountQueryResults
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
        return Account.all()
    }

    /// Instantiates a folder hierarchy model with:
    /// One section per account
    /// One row per folder
    /// If no account is given, all accounts found in the store are taken into account.
    /// - Parameter accounts: accounts to to create folder hierarchy view model for.
    public init(withFoldersIn accounts: [Account]? = nil, isUnified: Bool = true) {
        items = [FolderSectionViewModel]()
        accountQueryResults = AccountQueryResults()
        accountQueryResults.rowDelegate = self
        startMonitoring()
        let accountsToUse: [Account]
        if let safeAccounts = accounts {
            accountsToUse = safeAccounts
        } else {
            accountsToUse = allAccounts
        }
        let includeInUnifiedFolders = isUnified && shouldShowUnifiedFolders
        generateSections(accounts: accountsToUse, includeInUnifiedFolders: includeInUnifiedFolders)
    }

    /// Start monitoring accounts
    private func startMonitoring() {
        do {
            try accountQueryResults.startMonitoring()
        } catch {
            Log.shared.errorAndCrash("Error trying to start monitoring")
        }
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

// MARK: - QueryResultsIndexPathRowDelegate

extension FolderViewModel : QueryResultsIndexPathRowDelegate {

    public func didMoveRow(from: IndexPath, to: IndexPath) {
        // Intentionally we do not trigger any action
    }

    public func willChangeResults() {
        // Intentionally we do not trigger any action
    }

    public func didChangeResults() {
        queryResultsDelegateHandlingQueue.addOperation { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed.
                return
            }
            me.items = [FolderSectionViewModel]()
            DispatchQueue.main.async {
                me.generateSections(accounts: me.allAccounts, includeInUnifiedFolders: me.shouldShowUnifiedFolders)
                me.update()
            }
        }
    }

    public func didInsertRow(indexPath: IndexPath) {
        // Intentionally we do not trigger any action
    }

    public func didUpdateRow(indexPath: IndexPath) {
        // Intentionally we do not trigger any action
    }

    public func didDeleteRow(indexPath: IndexPath) {
        // Intentionally we do not trigger any action
    }

    private func update() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed.
                return
            }
            me.delegate?.update()
        }
    }
}
