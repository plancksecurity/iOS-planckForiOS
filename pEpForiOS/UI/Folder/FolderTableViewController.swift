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

class FolderTableViewController: BaseTableViewController {

    /// Every indentation level will move the cell this distance to the right.
    private let subFolderIndentationWidth: CGFloat = 25.0
    /// The hidden sections are the collapsed accounts.
    private var hiddenSections = Set<Int>()
    /// The hidden folders are the collapsed mail folders.
    private var hiddenFolders = Set<IndexPath>()

    var folderVM: FolderViewModel?
    var showNext: Bool = true
    var subfoldersHidden = false

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
        self.navigationController?.setToolbarHidden(false, animated: false)
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

    // MARK: - Action

    @objc private func showCompose() {
        UIUtils.presentComposeView(forRecipientInUrl: nil, appConfig: appConfig)
    }
    
    @objc private func showSettingsViewController() {
        UIUtils.presentSettings(appConfig: appConfig)
    }

    // MARK: - Cell Setup

    private func setNotSelectableStyle(to cell: FolderTableViewCell) {
        cell.chevronButton.isHidden = true
        cell.titleLabel?.textColor = UIColor.pEpGray
    }

    private func setSelectableStyle(to cell: FolderTableViewCell) {
        cell.chevronButton.isHidden = false
        cell.titleLabel?.textColor = UIColor.black
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return folderVM?.count ?? 0
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

        let numberOfRowsInSection = folderVM?[section].count ?? 0

        let hiddenFoldersInSection = hiddenFolders.filter({$0.section == section })
        var subfolderIPs = [IndexPath]()

        //Search sub-folders of this root folder.
        hiddenFoldersInSection.forEach { (rootIndexPath) in


            //Folder cell view model
            let folderCellViewModel = vm[rootIndexPath.section][rootIndexPath.item]

            //Iterate over the folder cell view models to grab the children nodes.
            var nextIndexPath = IndexPath(item: rootIndexPath.item + 1, section: section)
            while isSubfolder(indexPath: nextIndexPath) {
                let childFolderCellViewModel = vm[nextIndexPath.section][nextIndexPath.item]

                //Append only its childs.
                if folderCellViewModel.isParentOf(fcvm: childFolderCellViewModel) {
                    subfolderIPs.append(nextIndexPath)
                }
                nextIndexPath = IndexPath(item: nextIndexPath.item + 1, section: section)
            }
        }

        let numberOfHiddenRowsInSection = subfolderIPs.count
        return numberOfRowsInSection - numberOfHiddenRowsInSection
    }

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        let header: CollapsibleTableViewHeader?
        if let head = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
            as? CollapsibleTableViewHeader {
            header = head
        } else {
            header = CollapsibleTableViewHeader(reuseIdentifier: "header")
        }
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

    private func hasSubfolders(indexPath: IndexPath) -> Bool {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No model")
            return false
        }
        let fcvm = vm[indexPath.section][indexPath.item]
        return fcvm.hasSubfolders()
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No model")
            return UITableViewCell()
        }
        let fcvm = vm[indexPath.section][indexPath.item]

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SubFolderTableViewCell2", for: indexPath) as? SubFolderTableViewCell2 else {
            Log.shared.errorAndCrash("No subfolder cell found")
            return UITableViewCell()
        }
        cell.indentationWidth = subFolderIndentationWidth
        let subLevel = isSubfolder(indexPath: indexPath) ?  1 : 0
        cell.indentationLevel = fcvm.level + subLevel
        cell.titleLabel.text = fcvm.title
        cell.iconImageView.image = fcvm.image
        cell.delegate = self
        cell.hasSubfolders = hasSubfolders(indexPath: indexPath)
        cell.isExpand = fcvm.isExpand
        cell.titleLabel?.textColor = fcvm.isSelectable ? .black : .pEpGray
        cell.separatorImageView.isHidden = fcvm.shouldHideSeparator()
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

    // MARK: - Segue

    @IBAction func addAccountTapped(_ sender: Any) {
        performSegue(withIdentifier: .newAccount, sender: self)
    }

    /**
     Unwind segue for the case of adding an account that requires manual setup
     */
    @IBAction func segueUnwindAfterAccountCreation(segue:UIStoryboardSegue) {
        showNext = true
    }

    @IBAction func segueUnwindLastAccountDeleted(segue:UIStoryboardSegue) {
        showNext = true
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
}

// MARK: - Subfolder Indentation

extension FolderTableViewController {
    private func isSubfolder(indexPath: IndexPath) -> Bool {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No model")
            return false
        }

        if let folder = vm[indexPath.section][indexPath.item].folder as? Folder {
            if folder.folderType == .normal && folder.folderType != .outbox {
                return true
            }
        }
        return false
    }
}

// MARK: - FolderTableViewCellDelegate

extension FolderTableViewController: FolderTableViewCellDelegate {

    /// Callback
    ///
    /// - Parameters:
    ///   - cell: The cell that trigger the action
    func didTapChevronButton(cell:  UITableViewCell) {
        guard let currentIp = tableView.indexPath(for: cell) else { return }
        guard hasSubfolders(indexPath: currentIp) else { return }
        hideShowSubFolders(ofRowAt:  currentIp)
    }
}

// MARK: - Collapse

extension FolderTableViewController {

    /// Shows/Hides the selected account.
    /// - Parameter sender: The button that trigger the action.
    @objc
    private func hideShowSection(sender: SectionButton) {
        let section = sender.section
        func indexPathsForSection() -> [IndexPath] {
            var indexPaths = [IndexPath]()
            let numberOfRows = folderVM?[section].count ?? 0
            for row in 0 ..< numberOfRows {
                let ip = IndexPath(row: row, section: section)
                indexPaths.append(ip)
            }
            return indexPaths
        }
        if hiddenSections.contains(section) {
            sender.imageView?.transform = CGAffineTransform.rotate90Degress()
            hiddenSections.remove(section)
            tableView.insertRows(at: indexPathsForSection(), with: .fade)
        } else {
            sender.imageView?.transform = .identity
            hiddenSections.insert(section)
            tableView.deleteRows(at: indexPathsForSection(), with: .top)
        }
    }

    /// Shows/Hides the subfolder of the selected one.
    /// - Parameter indexPath: The indexPath of the selected folder.
    private func hideShowSubFolders(ofRowAt indexPath:  IndexPath) {
        var subfolderIPs = [IndexPath]()

        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No view model.")
            return
        }

        func extractChildIndexPath(_ section: Int) {
            //Folder cell view model
            let folderCellViewModel = vm[indexPath.section][indexPath.item]

            //Iterate over the folder cell view models to grab the children nodes.
            var nextIndexPath = IndexPath(item: indexPath.item + 1, section: section)
            while isSubfolder(indexPath: nextIndexPath) {
                let childFolderCellViewModel = vm[nextIndexPath.section][nextIndexPath.item]

                //Append only its childs.
                if folderCellViewModel.isParentOf(fcvm: childFolderCellViewModel) {
                    subfolderIPs.append(nextIndexPath)
                }
                nextIndexPath = IndexPath(item: nextIndexPath.item + 1, section: section)
            }
        }

        /// If the subfolders are hidden, show them.
        /// That means to insert the new rows and rotate the chevron icon down.
        /// Otherwise perform the opposite action,
        /// remove the subfolder's cells and rotate the chevron icon to the right.
        if hiddenFolders.contains(indexPath) {
            hiddenFolders.remove(indexPath)
            let folderCellViewModel = vm[indexPath.section][indexPath.item]
            folderCellViewModel.isExpand = true
            tableView.insertRows(at: childrenOfFolder(fromRowAt: indexPath), with: .fade)
        } else {
            hiddenFolders.insert(indexPath)
            let folderCellViewModel = vm[indexPath.section][indexPath.item]
            folderCellViewModel.isExpand = false
            tableView.deleteRows(at: childrenOfFolder(fromRowAt: indexPath), with: .top)
        }
    }


    /// - Returns: The indexPaths of the sub folders of the folder passed by paramter.
    private func childrenOfFolder(fromRowAt indexPath: IndexPath) -> [IndexPath] {
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No view model.")
            return [IndexPath]()
        }

        var subfolderIPs = [IndexPath]()

        //Folder cell view model
        let folderCellViewModel = vm[indexPath.section][indexPath.item]

        //Iterate over the folder cell view models to grab the children nodes.
        var nextIndexPath = IndexPath(item: indexPath.item + 1, section: indexPath.section)
        while isSubfolder(indexPath: nextIndexPath) {
            let childFolderCellViewModel = vm[nextIndexPath.section][nextIndexPath.item]

            //Append only its childs.
            if folderCellViewModel.isParentOf(fcvm: childFolderCellViewModel) {
                subfolderIPs.append(nextIndexPath)
            }
            nextIndexPath = IndexPath(item: nextIndexPath.item + 1, section: indexPath.section)
        }
        return subfolderIPs
    }
}
