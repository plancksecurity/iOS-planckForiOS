//
//  FolderTableViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 16/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox
import MessageModel

class FolderTableViewController: UITableViewController {

    var folderVM: FolderViewModel?

    // Indicates if it's needed to lead the user to a new screen,
    // the email list or the new account, for example.
    private var shouldPresentNextView: Bool = true

    @IBOutlet private weak var addAccountButton: UIButton!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfig()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pEpSettingsChanged),
                                               name: .pEpSettingsChanged,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pEpMDMSettingsChanged),
                                               name: .pEpMDMSettingsChanged,
                                               object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        showNextViewIfNeeded()
        showEmptyDetailViewIfNeeded()
        updateRefreshControl()
        folderVM?.refreshFolderList()
        UIUtils.hideBanner()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }
        if thePreviousTraitCollection.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }

        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                guard let vm = folderVM else {
                    Log.shared.errorAndCrash("VM not found")
                    return
                }
                vm.handleAppereanceChanged()
                Appearance.configureSelectedBackgroundViewForPep(tableViewCell: UITableViewCell.appearance())
                tableView.reloadData()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setup() {
        navigationController?.setToolbarHidden(false, animated: false)
        tableView.reloadData()
    }

    private func showEmptyDetailViewIfNeeded() {
        let message = NSLocalizedString("Please choose a folder", comment: "No folder has been selected yet in the folders VC")
        showEmptyDetailViewIfApplicable(message: message)
    }

    private func initialConfig() {
        folderVM = FolderViewModel()
        folderVM?.delegate = self
        if let vm = folderVM {
            addAccountButton.isHidden = !vm.shouldShowAddAccountButton
        }
        title = NSLocalizedString("Mailboxes", comment: "FoldersView navigationbar title")
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 80.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.pEpGreen
        tableView.refreshControl = refreshControl
        refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        let item = UIBarButtonItem.getPEPButton(
            action:#selector(showSettingsViewController),
            target: self)
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
            target: nil,
            action: nil)
        let compose = UIBarButtonItem.getComposeButton(
            tapAction: #selector(showCompose),
            longPressAction: #selector(draftsPreviewTapped),
            target: self)
        toolbarItems = [flexibleSpace, compose, flexibleSpace, item]
        tableView.cellLayoutMarginsFollowReadableWidth = false
        addAccountButton.titleLabel?.numberOfLines = 0
        addAccountButton.titleLabel?.setPEPFont(style: .body, weight: .regular)
        addAccountButton.accessibilityTraits = .button
        addAccountButton.accessibilityIdentifier = AccessibilityIdentifier.addAccountButton
    }

    // MARK: - Action

    @objc private func pullToRefresh() {
        folderVM?.refreshFolderList() { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            me.setup()
            me.refreshControl?.endRefreshing()
        }
    }

    @objc private func showCompose() {
        UIUtils.showComposeView(from: nil)
    }
    
    @objc private func showSettingsViewController() {
        UIUtils.showSettings()
    }

    @objc func draftsPreviewTapped(sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        UIUtils.presentDraftsPreview()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = folderVM else {
            //As folderVM is initialized on the setup method (first time in viewWillAppear), it might be nil the first time.
            return 0
        }
        return vm.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }

        /// Hidden sections are hidden!
        if vm.hiddenSections.contains(section) {
            return 0
        }
        // number of rows means number of visible rows.
        return vm[section].numberOfRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No VM")
            return UITableViewCell()
        }

        let fcvm = vm[indexPath.section].visibleFolderCellViewModel(index: indexPath.item)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FolderTableViewCell", for: indexPath)
            as? FolderTableViewCell else {
            Log.shared.errorAndCrash("No subfolder cell found")
            return UITableViewCell()
        }
        Appearance.configureSelectedBackgroundViewForPep(tableViewCell: cell)

        // Setup cell: padding, indentation, texts, colors, separator, chevron, etc.
        cell.indentationLevel = min(fcvm.indentationLevel, vm.maxIndentationLevel)
        cell.shouldRotateChevron = fcvm.shouldRotateChevron
        cell.chevronButton.isUserInteractionEnabled = fcvm.isChevronEnabled
        cell.padding = fcvm.padding
        cell.titleLabel.text = fcvm.title
        cell.titleLabel.setPEPFont(style: .body, weight: .regular)

        if #available(iOS 13.0, *) {
            cell.titleLabel?.textColor = fcvm.isSelectable ? .label : .tertiaryLabel
        } else {
            cell.titleLabel?.textColor = fcvm.isSelectable ? .black : .pEpGray
        }

        cell.unreadMailsLabel.font = UIFont.pepFont(style: .body, weight: .regular)
        let numUnreadMails = fcvm.numUnreadMails
        cell.unreadMailsLabel.text = numUnreadMails > 0 ? String(numUnreadMails) : ""
        cell.iconImageView.image = fcvm.image
        cell.separatorImageView.isHidden = fcvm.shouldHideSeparator()
        cell.delegate = self
        return cell
    }

    // MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let folderViewModel = folderVM else {
            Log.shared.errorAndCrash("No VM")
            return
        }

        // We only access to visible folders.
        let cellViewModel = folderViewModel[indexPath.section].visibleFolderCellViewModel(index: indexPath.row)
        if !cellViewModel.isSelectable {
            // Me must not open unselectable folders. Unselectable folders are typically path
            // components/nodes that can not hold messages.
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        showEmailList(folder: cellViewModel.folder)
    }
}

// MARK: - LoginTableViewControllerDelegate

extension FolderTableViewController: LoginViewControllerDelegate {
    func loginViewControllerDidCreateNewAccount(_ loginViewController: LoginViewController) {
        setup()
        // The user has just logged in, he should see the email list view.
        shouldPresentNextView = true
    }
}

// MARK: - Segue

extension FolderTableViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case newAccount
        case settingsSegue
        case mdmPredeployAccounts
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueId = segueIdentifier(for: segue)

        switch segueId {
        case .newAccount:
            guard
                let nav = segue.destination as? UINavigationController,
                let vc = nav.rootViewController as? AccountTypeSelectorViewController else {
                    Log.shared.errorAndCrash("Missing VCs")
                    return
            }
            vc.loginDelegate = self
            nav.modalPresentationStyle = .fullScreen
            vc.hidesBottomBarWhenPushed = true

        case .settingsSegue:
            guard let dvc = segue.destination as? SettingsTableViewController else {
                Log.shared.errorAndCrash("Error casting DVC")
                return
            }
            dvc.hidesBottomBarWhenPushed = true

        case .mdmPredeployAccounts:
            guard let navVC = segue.destination as? UINavigationController,
                  let vc = navVC.rootViewController as? MDMAccountPredeploymentViewController else {
                Log.shared.errorAndCrash("Error casting to MDMAccountPredeploymentViewController")
                return
            }
            navVC.modalPresentationStyle = .fullScreen
            vc.hidesBottomBarWhenPushed = true
        }
    }

    private func updateRefreshControl() {
        /// This fixes a UI glitch.
        /// The refresh control gets stucked when a view controller is pushed over the current one and dismissed.
        /// This works around that issue. If the refresh control is refreshing, make it spin again.
        /// If not, it is already hidden, so nothing to do.
        if refreshControl?.isRefreshing ?? false {
            refreshControl?.endRefreshing()
            refreshControl?.beginRefreshing()
        }
    }

    // MARK: Action

    @IBAction private func addAccountTapped(_ sender: Any) {
        performSegue(withIdentifier: .newAccount, sender: self)
    }

     /// Unwind segue for the case of adding an account that requires manual setup
    @IBAction private func segueUnwindAfterAccountCreation(segue: UIStoryboardSegue) {
        // After adding an account with manual setup the user should see the email list view
        shouldPresentNextView = true
    }

    @IBAction private func segueUnwindLastAccountDeleted(segue: UIStoryboardSegue) {
        // The last account was deleted, so the user should be prompt to add a new one.
        shouldPresentNextView = true
    }

    /// If needed, will show the email list of new account view.
    private func showNextViewIfNeeded() {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("VM not Found")
            return
        }

        if shouldPresentNextView {
            if vm.shouldShowFolders {
                showEmailList(folder:vm.folderToShow)
            } else {
                if MDMPredeployed().haveAccountsToPredeploy {
                    performSegue(withIdentifier:.mdmPredeployAccounts, sender: self)
                } else {
                    performSegue(withIdentifier:.newAccount, sender: self)
                }
            }
        }
    }

    /// Show folder in email list
    /// - Parameter folder: The folder to show.
    private func showEmailList(folder: DisplayableFolderProtocol) {
        let sb = UIStoryboard(name: Constants.mainStoryboard, bundle: nil)
        guard
            let vc = sb.instantiateViewController(
                withIdentifier: EmailListViewController.storyboardId) as? EmailListViewController
            else {
                Log.shared.errorAndCrash("Problem!")
                return
        }
        vc.viewModel = EmailListViewModel(delegate: vc, folderToShow: folder)
        vc.hidesBottomBarWhenPushed = false
        let animated = !shouldPresentNextView

        // The user will see the email list now, if he goes back, let him here
        shouldPresentNextView = false
        navigationController?.pushViewController(vc, animated: animated)
    }
}

// MARK: - Subfolder Indentation

extension FolderTableViewController {

    /// Indicates if a folder has subfolders
    /// - Parameter indexPath: To identify the cell to look for its subfolders.
    /// - Returns: True if the folder has subfolders.
    private func hasSubfolders(indexPath: IndexPath) -> Bool {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No View Model")
            return false
        }
        let fcvm = vm[indexPath.section].visibleFolderCellViewModel(index: indexPath.item)
        return fcvm.hasSubfolders()
    }

    /// Indicates if the a folder is a subfolder
    /// - Parameter indexPath: To identify the cell to check if it's a subfolder.
    /// - Returns: True if it is.
    private func isSubfolder(indexPath: IndexPath) -> Bool {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No View Model")
            return false
        }

        return vm[indexPath.section].visibleFolderCellViewModel(index: indexPath.item).isSubfolder()
    }
}

// MARK: - FolderTableViewCellDelegate

extension FolderTableViewController: FolderTableViewCellDelegate {

    /// Callback executed when the chevron arrow is tapped.
    /// - Parameter cell: The cell which trigger the action.
    public func didTapChevronButton(cell:  UITableViewCell) {
        guard let currentIp = tableView.indexPath(for: cell) else { return }
        guard hasSubfolders(indexPath: currentIp) else { return }
        hideShowSubFolders(ofRowAt:  currentIp)
    }
}

// MARK: - Collapse / Expand

extension FolderTableViewController {

    /// Shows/Hides the selected account.
    /// - Parameter sender: The button that trigger the action.
    @objc
    private func hideShowSection(sender: SectionButton) {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No VM.")
            return
        }
        // Number of section
        let section = sender.section

        // Toogle section visibility.
        if vm.hiddenSections.contains(section) {
            setFoldingArrowState(isCollapsed: false, to: sender)
            vm.handleCollapsingSectionStateChanged(forAccountInSection: section, isCollapsed: false)
        } else {
            setFoldingArrowState(isCollapsed: true, to: sender)
            vm.handleCollapsingSectionStateChanged(forAccountInSection: section, isCollapsed: true)
        }
    }

    /// Shows/Hides the subfolder of the selected one.
    /// - Parameter indexPath: The indexPath of the selected folder.
    private func hideShowSubFolders(ofRowAt indexPath: IndexPath) {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No view model.")
            return
        }

        /// The indexPaths of the subfolders
        /// - Parameter isExpand: Indicates if the parent is Expanded
        /// - Returns: The children's Indexpaths.
        func childrenIndexPaths(isParentExpand isExpanded: Bool) -> [IndexPath] {
            let section = indexPath.section
            let sectionViewModel = vm[section]
            var childrenIndexPaths = [IndexPath]()

            let children = sectionViewModel.children(of: folderCellViewModel).filter { $0.isHidden == isExpanded }

            // if not expanded, we will collapse, otherwise we will expand
            if !isExpanded {
                children.forEach {
                    guard let row = sectionViewModel.visibleIndex(of: $0) else {
                        Log.shared.errorAndCrash("Item not found")
                        return
                    }
                    let childrenIndexPath = IndexPath(row:row, section:section)
                    childrenIndexPaths.append(childrenIndexPath)
                }
                return childrenIndexPaths
            } else {
                let numberOfRowsToShow = vm.expandCellAndGetTheNumberOfRowsToInsert(ofSection: section, folderCellViewModel: folderCellViewModel)
                for i in 0 ..< numberOfRowsToShow {
                    let childIndexPath = IndexPath(item: indexPath.item + i + 1, section: section)
                    childrenIndexPaths.append(childIndexPath)
                }
                return childrenIndexPaths
            }
        }

        //Expand or collapse the root folder
        let folderCellViewModel = vm[indexPath.section].visibleFolderCellViewModel(index: indexPath.item)
        folderCellViewModel.isExpanded.toggle()
        let childrenIPs = childrenIndexPaths(isParentExpand : folderCellViewModel.isExpanded)
        if !folderCellViewModel.isExpanded {
            let children = vm[indexPath.section].children(of: folderCellViewModel)
            children.forEach {
                $0.isHidden = !folderCellViewModel.isExpanded
                $0.isExpanded = folderCellViewModel.isExpanded
            }
        }

        // Insert or delete rows
        if folderCellViewModel.isExpanded {
            tableView.insertRows(at: childrenIPs)
        } else {
            tableView.deleteRows(at: childrenIPs)
        }
        folderCellViewModel.handleFolderCollapsedStateChange(to: !folderCellViewModel.isExpanded)
    }
}


// MARK: - Header and Footer

extension FolderTableViewController {

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        let header: CollapsibleTableViewHeader?
        if let head = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
            as? CollapsibleTableViewHeader {
            header = head
        } else {
            header = CollapsibleTableViewHeader(reuseIdentifier: "header")
        }

        // Transparent button to collapse/expand the section.
        header?.sectionButton.section = section
        header?.sectionButton.addTarget(self,
                                        action: #selector(hideShowSection(sender:)),
                                        for: .touchUpInside)
        header?.sectionButton.accessibilityIdentifier = AccessibilityIdentifier.showHideFoldersButton
        let arrow = UIImage(named:"chevron-icon-right-gray")
        header?.sectionButton.setImage(arrow, for: .normal)
        header?.sectionButton.contentHorizontalAlignment = .trailing
        header?.sectionButton.contentVerticalAlignment = .top
        guard let vm = folderVM, let safeHeader = header else {
            Log.shared.errorAndCrash("No header or no VM.")
            return header
        }

        guard let sectionButton = header?.sectionButton else {
            Log.shared.errorAndCrash("Section button is missing")
            return header
        }
        setFoldingArrowState(isCollapsed: vm[section].isCollapsed, to: sectionButton)

        if vm[section].sectionHeaderHidden {
            return nil
        }

        safeHeader.configure(viewModel: vm[section], section: section)
        return header
    }


    func setFoldingArrowState(isCollapsed: Bool, to button: SectionButton) {
        button.imageView?.transform = isCollapsed ? .identity : CGAffineTransform.rotate90Degress()
    }

    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        return 26.0
    }

    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No VM.")
            return 0.0
        }
        if vm[section].sectionHeaderHidden {
            return 0.0
        } else {
            return tableView.sectionHeaderHeight
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // In iOS12, the first subview (_UITableViewHeaderFooterViewBackground) has a gray background.
        // Remove this when iOS 12 support is dropped.
        guard #available(iOS 13, *) else {
            if let header = view as? UITableViewHeaderFooterView, let subview = header.subviews.first {
                subview.backgroundColor = .white
            }
            return
        }
    }
}

// MARK:- FolderViewModelDelegate

extension FolderTableViewController : FolderViewModelDelegate {
    func insertRowsAtIndexPaths(indexPaths: [IndexPath]) {
        tableView.insertRows(at: indexPaths)
    }

    func deleteRowsAtIndexPaths(indexPaths: [IndexPath]) {
        tableView.deleteRows(at: indexPaths)
    }
}

//MARK: - pEp Settings Changed

extension FolderTableViewController {

    @objc func pEpSettingsChanged() {
        tableView.reloadData()
    }

    @objc func pEpMDMSettingsChanged() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        addAccountButton.isHidden = !vm.shouldShowAddAccountButton
    }
}
