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

    private var hiddenSections = Set<Int>()

    var folderVM: FolderViewModel?
    var showNext: Bool = true

    @IBOutlet private weak var addAccountButton: UIButton!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfig()
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

    private func setNotSelectableStyle(to cell: UITableViewCell) {
        cell.accessoryType = .none
        cell.textLabel?.textColor = UIColor.pEpGray
    }

    private func setSelectableStyle(to cell: UITableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = UIColor.black
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return folderVM?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.hiddenSections.contains(section) {
            return 0
        }

        return folderVM?[section].count ?? 0
    }

    @objc
    private func hideSection(sender: UIButton) {
        let section = sender.tag
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
            sender.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
            hiddenSections.remove(section)
            tableView.insertRows(at: indexPathsForSection(), with: .fade)
        } else {
            sender.imageView?.transform = .identity
            hiddenSections.insert(section)
            tableView.deleteRows(at: indexPathsForSection(), with: .top)
        }
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
        //TODO: avoid tag. 
        header?.transparentButton.tag = section
        header?.transparentButton.addTarget(self, action: #selector(hideSection(sender:)), for: .touchUpInside)
//        let arrow = UIImage(named:"chevron-icon")
        let arrow = UIImage(named:"compose")

        header?.transparentButton.setImage(arrow, for: .normal)
        header?.transparentButton.contentHorizontalAlignment = .trailing
        header?.transparentButton.contentVerticalAlignment = .top
        header?.transparentButton.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))

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
        return 0.0
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
        guard let vm = folderVM else {
            Log.shared.errorAndCrash("No model")
            return cell
        }
        let fcvm = vm[indexPath.section][indexPath.item]
        cell.textLabel?.text = fcvm.title
        cell.imageView?.image = fcvm.image

        if fcvm.isSelectable {
            setSelectableStyle(to: cell)
        } else {
            setNotSelectableStyle(to: cell)
        }
        cell.indentationWidth = 20.0
        return cell
    }

    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath)
        -> Int {
            guard let vm = folderVM else {
                Log.shared.errorAndCrash("No model")
                return 0
            }
            return vm[indexPath.section][indexPath.item].level
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
