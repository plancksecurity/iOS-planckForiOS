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


public protocol FolderVideModelDelegate: class {

    /// Inform the VC to insert rows in the givven indexpaths
    /// - Parameter indexPaths: The indexPath of the rows.
    func insertRowsAtIndexPaths(indexPaths: [IndexPath])

    /// Inform the VC to delete rows in the givven indexpaths
    /// - Parameter indexPaths: The indexPath of the rows.
    func deleteRowsAtIndexPaths(indexPaths: [IndexPath])
}

/// View Model for folder hierarchy.
public class FolderViewModel {

    private var appSettings: AppSettingsProtocol
    public weak var delegate: FolderVideModelDelegate?
    private lazy var folderSyncService = FetchImapFoldersService()
    public var items: [FolderSectionViewModel]

    /// The hidden sections are the collapsed accounts.
    public var hiddenSections = Set<Int>()

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
    public init(withFoldersIn accounts: [Account]? = nil, isUnified: Bool = true, appSettings: AppSettingsProtocol = AppSettings.shared) {
        self.appSettings = appSettings
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

//MARK:- Show/Hide rows.

extension FolderViewModel {

    public func handleCollapsingSectionStateChanged(forAccountInSection section: Int, isCollapsed: Bool) {
        guard let delegate = delegate else {
            // The Delegate is needed to handle this.
            Log.shared.errorAndCrash("Delegate not found.")
            return
        }
        let address = items[section].userAddress
        appSettings.setAccountCollapsedState(address: address, isCollapsed: isCollapsed)
        if isCollapsed {
            hiddenSections.insert(section)
            let indexPaths = hideRows(ofSection: section)
            delegate.deleteRowsAtIndexPaths(indexPaths: indexPaths)
        } else {
            hiddenSections.remove(section)
            let indexPath = showRows(ofSection: section)
            delegate.insertRowsAtIndexPaths(indexPaths: indexPath)
        }
    }

    private func hideRows(ofSection section: Int) -> [IndexPath] {
        var rowsToHide = 0
        self[section].isCollapsed = true
        for i in 0..<self[section].count {

            // If it is not hidden, lets hide it.
            if !self[section][i].isHidden {
                self[section][i].isHidden = true
                rowsToHide += 1
            }
        }

        var ipsToReturn = [IndexPath]()
        for row in 0..<rowsToHide {
            let ip = IndexPath(row: row, section: section)
            ipsToReturn.append(ip)
        }

        return ipsToReturn
    }

    private func showRows(ofSection section: Int) -> [IndexPath] {
        var rowsToShow = 0
        self[section].isCollapsed = false

        /// Keep track of collapsed rows to hide its children.
        var collapsedRows = [FolderCellViewModel]()

        /// iterate over all FolderCellViewModels
        for i in 0..<self[section].count {

            guard let f: Folder = self[section][i].folder as? Folder else {
                Log.shared.errorAndCrash("A Folder should be a Folder")
                return [IndexPath]()
            }

            // Check if the folder is collapsed.
            let isFolderCollapsed = appSettings.collapsedState(forFolderNamed: f.name,
                                                               ofAccountWithAddress: self[section].userAddress)
            /// If the folder is collapsed, it's visible and not expanded.
            /// If the folder is not collapsd, it's expanded.
            /// If it's expanded but any of its ancestors is collapsed, it should be hidden.
            if isFolderCollapsed {
                collapsedRows.append(self[section][i])
                self[section][i].isExpanded = false
                self[section][i].isHidden = false
                rowsToShow += 1
            } else {
                self[section][i].isExpanded = true
                var shouldShow = true

                /// Check if any of the colllapsed rows is ancestor of the current row.
                if collapsedRows.contains(where: {$0.isAncestorOf(fcvm: self[section][i])}) {
                    shouldShow = false
                }
                if shouldShow {
                    self[section][i].isHidden = false
                    rowsToShow += 1
                } else {
                    self[section][i].isHidden = true
                }
            }
        }
        var ipsToReturn = [IndexPath]()
        for row in 0..<rowsToShow {
            let ip = IndexPath(row: row, section: section)
            ipsToReturn.append(ip)
        }
        return ipsToReturn
    }
}

