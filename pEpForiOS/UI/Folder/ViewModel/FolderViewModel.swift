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


public protocol FolderViewModelDelegate: class {

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
    public weak var delegate: FolderViewModelDelegate?
    private lazy var folderSyncService = FetchImapFoldersService()
    public var items: [FolderSectionViewModel] = [FolderSectionViewModel]()

    /// The hidden sections are the collapsed accounts.
    public var hiddenSections = Set<Int>()

    public var maxIndentationLevel: Int {
        return UIDevice.isSmall ? 3 : 4
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
        self.generateSections(accounts: accounts, isUnified: isUnified)
    }

    private func generateSections(accounts: [Account]?, isUnified: Bool) {
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

    /// Handle collapsing state change of the section passed by parameter
    /// - Parameters:
    ///   - section: The section that has changed
    ///   - isCollapsed: The new collapsing state.
    public func handleCollapsingSectionStateChanged(forAccountInSection section: Int, isCollapsed: Bool) {
        guard let delegate = delegate else {
            // The Delegate is needed to handle this.
            Log.shared.errorAndCrash("Delegate not found.")
            return
        }
        let address = items[section].userAddress
        appSettings.setCollapsedState(forAccountWithAddress: address, to: isCollapsed)
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
        self[section].isCollapsed = false
        var collapsedRows = [FolderCellViewModel]()
        var rowsToShow = 0

        for item in 0..<self[section].count {
            calculateRowsToShow(&collapsedRows, section, item, &rowsToShow)
        }

        var ipsToReturn = [IndexPath]()
        for row in 0..<rowsToShow {
            let ip = IndexPath(row: row, section: section)
            ipsToReturn.append(ip)
        }
        return ipsToReturn
    }

    /// Expands the cell and get the
    /// - Parameters:
    ///   - section: The section of the cell to expand
    ///   - folderCellViewModel: The Folder Cell View Model of the cell to expand
    /// - Returns: The number of rows to insert.
    public func expandCellAndGetTheNumberOfRowsToInsert(ofSection section: Int, folderCellViewModel: FolderCellViewModel) -> Int {
        var rowsToShow = 0
        var collapsedRows = [FolderCellViewModel]()
        let childrenFolderCellViewModels = self[section].children(of: folderCellViewModel)
        for item in 0..<self[section].count {
            if !childrenFolderCellViewModels.contains(self[section][item]) {
                continue
            }
            calculateRowsToShow(&collapsedRows, section, item, &rowsToShow)
        }
        return rowsToShow
    }

    private func calculateRowsToShow(_ collapsedRows: inout [FolderCellViewModel], _ sectionIndex: Int, _ itemIndex: Int, _ rowsToShow: inout Int) {
        guard let folder: Folder = self[sectionIndex][itemIndex].folder as? Folder else {
            Log.shared.errorAndCrash("A Folder should be a Folder")
            return
        }
        let address = self[sectionIndex].userAddress
        let isFolderCollapsed = appSettings.folderViewCollapsedState(forFolderNamed: folder.name,
                                                           ofAccountWithAddress: address)
        if isFolderCollapsed {
            collapsedRows.append(self[sectionIndex][itemIndex])
            self[sectionIndex][itemIndex].isExpanded = false
            if !self[sectionIndex].hasAncestorsCollapsed(folderCellViewModel: self[sectionIndex][itemIndex]) {
                self[sectionIndex][itemIndex].isHidden = false
                rowsToShow += 1
            } else {
                self[sectionIndex][itemIndex].isHidden = true
            }
        } else {
            self[sectionIndex][itemIndex].isExpanded = true
            var shouldShow = true

            /// Check if any of the colllapsed rows is ancestor of the current row.
            if collapsedRows.contains(where: {$0.isAncestorOf(fcvm: self[sectionIndex][itemIndex])}) {
                shouldShow = false
            }
            if shouldShow {
                self[sectionIndex][itemIndex].isHidden = false
                rowsToShow += 1
            } else {
                self[sectionIndex][itemIndex].isHidden = true
            }
        }
    }
}

