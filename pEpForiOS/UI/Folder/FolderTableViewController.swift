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

final class FolderTableViewController: BaseTableViewController {

    /// The hidden sections are the collapsed accounts.
    private var hiddenSections = Set<Int>()

    var folderVM: FolderViewModel?
    var showNext: Bool = true

    var maxIndentationLevel: Int {
        return Device.isIphone5 ? 3 : 4
    }

    @IBOutlet private weak var addAccountButton: UIButton!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfig()
        tableView.cellLayoutMarginsFollowReadableWidth = false
        addAccountButton.titleLabel?.numberOfLines = 0
        addAccountButton.titleLabel?.font = UIFont.pepFont(style: .body, weight: .regular)
        addAccountButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()

        if showNext {
            show(folder: UnifiedInbox())
        }
        showEmptyDetailViewIfApplicable(
            message: NSLocalizedString(
                "Please choose a folder",
                comment: "No folder has been selected yet in the folders VC"))
    }

    // MARK: - Setup

    private func setup() {
        navigationController?.setToolbarHidden(false, animated: false)
        folderVM =  FolderViewModel()
        tableView.reloadData()
    }

    private func initialConfig() {
        title = NSLocalizedString("Mailboxes", comment: "FoldersView navigationbar title")
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 80.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.pEpGreen
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        }
        refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        let item = UIBarButtonItem.getPEPButton(
            action:#selector(showSettingsViewController),
            target: self)
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
            target: nil,
            action: nil)
        let compose = UIBarButtonItem.getComposeButton(
            action:#selector(showCompose),
            target: self)
        toolbarItems = [flexibleSpace, compose, flexibleSpace, item]
    }

    @objc private func pullToRefresh() {
        folderVM?.refreshFolderList() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(message: "Lost myself")
                return
            }
            me.setup()
            me.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = folderVM else {
            return 0
        }
        return vm.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /// Hidden sections are hidden!
        if hiddenSections.contains(section) {
            return 0
        }
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        // number of rows means number of visible rows.
        return vm[section].numberOfRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No model")
            return UITableViewCell()
        }

        let fcvm = vm[indexPath.section].visibleFolderCellViewModel(index: indexPath.item)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FolderTableViewCell", for: indexPath)
            as? FolderTableViewCell else {
            Log.shared.errorAndCrash("No subfolder cell found")
            return UITableViewCell()
        }

        /// Config cell
        // Indentation
        let subLevel = isSubfolder(indexPath: indexPath) ?  1 : 0
        let indentationLevel = fcvm.level + subLevel
        cell.indentationLevel = min(indentationLevel, maxIndentationLevel)
        cell.hasSubfolders = hasSubfolders(indexPath: indexPath)
        cell.isExpand = fcvm.isExpand

        // Title and icon
        cell.titleLabel.text = fcvm.title
        cell.titleLabel.font = UIFont.pepFont(style: .body, weight: .regular)
        cell.titleLabel.adjustsFontForContentSizeCategory = true
        cell.titleLabel?.textColor = fcvm.isSelectable ? .black : .pEpGray
        cell.iconImageView.image = fcvm.image

        //Separator line.
        // The native implementation is not compatible with our custom indentation.
        cell.separatorImageView.isHidden = fcvm.shouldHideSeparator()

        cell.delegate = self
        return cell
    }

    // MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let folderViewModel = folderVM else {
            Log.shared.errorAndCrash("No model")
            return
        }
        let cellViewModel = folderViewModel[indexPath.section][indexPath.row]
        if !cellViewModel.isSelectable {
            // Me must not open unselectable folders. Unselectable folders are typically path
            // components/nodes that can not hold messages.
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        show(folder: cellViewModel.folder)
    }

    private func show(folder: DisplayableFolderProtocol) {
        let sb = UIStoryboard(name: EmailViewController.storyboard, bundle: nil)
        guard
            let vc = sb.instantiateViewController(
                withIdentifier: EmailListViewController.storyboardId) as? EmailListViewController
            else {
                Log.shared.errorAndCrash("Problem!")
                return
        }
        vc.appConfig = appConfig
        let emailListVM = EmailListViewModel(delegate: vc,
                                             folderToShow: folder)
        vc.viewModel = emailListVM
        vc.hidesBottomBarWhenPushed = false

        let animated =  showNext ? false : true
        showNext = false
        self.navigationController?.pushViewController(vc, animated: animated)
    }
}

// MARK: - LoginTableViewControllerDelegate

extension FolderTableViewController: LoginViewControllerDelegate {
    func loginViewControllerDidCreateNewAccount(
        _ loginViewController: LoginViewController) {
        setup()
        showNext = true
    }
}

// MARK: - Segue

extension FolderTableViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case newAccount
        case settingsSegue
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
            nav.modalPresentationStyle = .fullScreen
            vc.appConfig = self.appConfig
            
            vc.hidesBottomBarWhenPushed = true

        case .settingsSegue:
            guard let dvc = segue.destination as? SettingsTableViewController else {
                Log.shared.errorAndCrash("Error casting DVC")
                return
            }
            dvc.appConfig = self.appConfig
            dvc.hidesBottomBarWhenPushed = true
        }
    }

    // MARK: Action

    @IBAction private func addAccountTapped(_ sender: Any) {
        performSegue(withIdentifier: .newAccount, sender: self)
    }

    /**
     Unwind segue for the case of adding an account that requires manual setup
     */
    @IBAction private func segueUnwindAfterAccountCreation(segue: UIStoryboardSegue) {
        showNext = true
    }

    @IBAction private func segueUnwindLastAccountDeleted(segue: UIStoryboardSegue) {
        showNext = true
    }

    @objc private func showCompose() {
        UIUtils.presentComposeView(forRecipientInUrl: nil, appConfig: appConfig)
    }

    @objc private func showSettingsViewController() {
        UIUtils.presentSettings(appConfig: appConfig)
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

        /// - Parameter numberOfRows: The number of rows to generate the indexPaths collection.
        /// - Returns: The IndexPaths of the current section using the number of rows passed by parameter
        func indexPathsBy(numberOfRows : Int) -> [IndexPath] {
            var indexPaths = [IndexPath]()
            for row in 0 ..< numberOfRows {
                let ip = IndexPath(row: row, section: section)
                indexPaths.append(ip)
            }
            return indexPaths
        }

        /// Modify the visibility of all rows in section
        /// - Parameter newValue: True to hide, false to show.
        func setAllRowsHidden(to newValue: Bool) {
            for i in 0..<vm[section].count {
                vm[section][i].isHidden = newValue
            }
        }

        /// - Returns: The indexPath of visibles rows in section.
        func indexPathsForSection() -> [IndexPath] {
            return indexPathsBy(numberOfRows: vm[section].numberOfRows)
        }

        /// - Returns: The indexPath of all rows in section.
        func allIndexPathsForSection() -> [IndexPath] {
            return indexPathsBy(numberOfRows: vm[section].count)
        }

        // Toogle section visibility.
        if hiddenSections.contains(section) {
            sender.imageView?.transform = CGAffineTransform.rotate90Degress()
            hiddenSections.remove(section)
            //Do not change the order of this methods as the next line change the hidden status
            let ips = allIndexPathsForSection()
            setAllRowsHidden(to: false)
            tableView.insertRows(at: ips)
        } else {
            sender.imageView?.transform = .identity
            hiddenSections.insert(section)
            //Do not change the order of this methods as the next line change the hidden status
            let ips = indexPathsForSection()
            setAllRowsHidden(to: true)
            tableView.deleteRows(at: ips)
        }
    }

    /// Shows/Hides the subfolder of the selected one.
    /// - Parameter indexPath: The indexPath of the selected folder.
    private func hideShowSubFolders(ofRowAt indexPath:  IndexPath) {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No view model.")
            return
        }

        /// The indexPaths of the subfolders
        /// - Parameter isExpand: Indicates if the parent is Expand
        /// - Returns: The children's Indexpaths.
        func childrenIndexPaths(isParentExpand isExpand : Bool) -> [IndexPath] {
            let sectionVM = vm[indexPath.section]
            var childrenIndexPaths = [IndexPath]()
            let children = sectionVM.children(of: folderCellViewModel).filter { $0.isHidden == isExpand }
            for i in 0 ..< children.count {
                let childIndexPath = IndexPath(item: indexPath.item + i + 1, section: indexPath.section)
                childrenIndexPaths.append(childIndexPath)
            }
            return childrenIndexPaths
        }

        //Expand or collapse the root folder
        let folderCellViewModel = vm[indexPath.section].visibleFolderCellViewModel(index: indexPath.item)
        folderCellViewModel.isExpand.toggle()
        let childrenIPs = childrenIndexPaths(isParentExpand : folderCellViewModel.isExpand)
        let children = vm[indexPath.section].children(of: folderCellViewModel)
        children.forEach { $0.isHidden = !folderCellViewModel.isExpand }

        // Insert or delete rows
        if folderCellViewModel.isExpand {
            tableView.insertRows(at: childrenIPs)
        } else {
            tableView.deleteRows(at: childrenIPs)
        }
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
        let arrow = UIImage(named:"chevron-icon-right-gray")
        header?.sectionButton.setImage(arrow, for: .normal)
        header?.sectionButton.contentHorizontalAlignment = .trailing
        header?.sectionButton.contentVerticalAlignment = .top
        header?.sectionButton.imageView?.transform = CGAffineTransform.rotate90Degress()

        guard let vm = folderVM, let safeHeader = header else {
            Log.shared.errorAndCrash("No header or no model.")
            return header
        }

        if vm[section].hidden {
            return nil
        }

        safeHeader.configure(viewModel: vm[section], section: section)
        return header
    }

    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        return 26.0
    }

    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No model.")
            return 0.0
        }
        if vm[section].hidden {
            return 0.0
        } else {
            return tableView.sectionHeaderHeight
        }
    }
}
