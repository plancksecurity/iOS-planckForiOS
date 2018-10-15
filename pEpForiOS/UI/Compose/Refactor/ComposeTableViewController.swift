//
//  ComposeTableViewController.swift
//  pEp
//
//  Created by Andreas Buff on 03.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel
import SwipeCellKit
import Photos

class ComposeTableViewController: BaseTableViewController {
    @IBOutlet var sendButton: UIBarButtonItem!

    private var suggestionsChildViewController: SuggestTableViewController?
    private var isInitialSetup = true
    private var currentCellIndexPath: IndexPath?
    var viewModel: ComposeViewModel? {
        didSet {
            // Make sure we are the delegate. Always.
            viewModel?.delegate = self
            tableView.reloadData()
        }
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        if viewModel == nil {
            setupModel()
        }
    }

    // MARK: - Setup & Configuration

    private func setupView() {
        tableView.rowHeight = UITableViewAutomaticDimension
         //IOS-1369 an arbitrary value auto resize seems to require for some reason.
        tableView.estimatedRowHeight = 1000
    }

    private func setupModel() {
        viewModel = ComposeViewModel()
    }

    private final func setupRecipientSuggestionsTableViewController() {
        let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: nil)
        guard
            let vm = viewModel,
            let suggestVc = storyboard.instantiateViewController(
                withIdentifier: SuggestTableViewController.storyboardId)
                as? SuggestTableViewController,
            let suggestView = suggestVc.view else {
                Log.shared.errorAndCrash(component: #function, errorString: "No VC.")
                return
        }
        suggestionsChildViewController = suggestVc
        suggestionsChildViewController?.viewModel = vm.suggestViewModel()
        addChildViewController(suggestVc)
        suggestView.isHidden = true
        updateSuggestTable()
        tableView.addSubview(suggestView)
    }

    // MARK: - IBActions

    @IBAction func cancel(_ sender: Any) {
        //IOS-1369:
        //        if edited {
        //            showAlertControllerWithOptionsForCanceling(sender: sender)
        //        } else {
                    dismiss()
        //        }
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func send() {
        //IOS-1369:
    }
}

// MARK: - PEP Color View

extension ComposeTableViewController {
    private func setupPepColorView(for pEpRating: PEP_rating, pEpProtected: Bool) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return
        }

        //IOS-1369: Not so nice. The view(controller) should not know about state and protection.
        if let view = showPepRating(pEpRating: pEpRating, pEpProtection: pEpProtected) {
            if vm.state.canHandshake() || vm.state.canToggleProtection() {
                let tapGestureRecognizer = UITapGestureRecognizer(
                    target: self,
                    action: #selector(actionHandshakeOrForceUnprotected))
                view.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }

    /// Shows a menu where user can choose to make a handshake, or toggle force unprotected.
    @objc func actionHandshakeOrForceUnprotected(gestureRecognizer: UITapGestureRecognizer) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return
        }
        let theCanHandshake = vm.state.canHandshake()
        let theCanToggleProtection = vm.state.canToggleProtection()

        if theCanHandshake || theCanToggleProtection {
            let alert = UIAlertController.pEpAlertController()

            if theCanHandshake {
                let actionReply = UIAlertAction(
                    title: NSLocalizedString("Handshake",
                                             comment: "possible privacy status action"),
                    style: .default) {/*[weak self]*/ (action) in
                        fatalError("IOS-1369: push handshake view. Need to get viewModeled first though")
//                        self?.performSegue(withIdentifier: .segueHandshake, sender: self)
                }
                alert.addAction(actionReply)
            }

            if theCanToggleProtection {
                let originalValueOfProtection = vm.state.pEpProtection
                let title = vm.state.pEpProtection ?
                    NSLocalizedString("Disable Protection",
                                      comment: "possible private status action") :
                    NSLocalizedString("Enable Protection",
                                      comment: "possible private status action")
                let actionToggleProtection = UIAlertAction(
                    title: title,
                    style: .default) { (action) in
                        vm.handleUserChangedProtectionStatus(to: !originalValueOfProtection)
                }
                alert.addAction(actionToggleProtection)
            }

            let cancelAction = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: "possible private status action"),
                style: .cancel) { (action) in }
            alert.addAction(cancelAction)

            present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - ComposeViewModelDelegate

extension ComposeTableViewController: ComposeViewModelDelegate {

    func validatedStateChanged(to isValidated: Bool) {
        sendButton.isEnabled = isValidated
    }

    func contentChanged(inRowAt indexPath: IndexPath) {
        //IOS-1369: indexPath currently unused.
        tableView.updateSize()
    }

    func modelChanged() {
        tableView.reloadData()
    }

    func colorBatchNeedsUpdate(for rating: PEP_rating, protectionEnabled: Bool) {
        setupPepColorView(for: rating, pEpProtected: protectionEnabled)
    }

    //IOS-1369: tmp. has to change. The receiver ComposeVC must not know Identity
//    func userSelectedRecipient(identity: Identity) {
//        guard
//            let indexPath = currentCellIndexPath,
//            let cell = tableView.cellForRow(at: indexPath) as? RecipientCell else {
//                Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
//                return
//        }
//        hideSuggestions()
//        cell.addIdentity(identity)
//        cell.textView.scrollToTop()
//        suggestionsChildViewController?.tableView.updateSize()
//    }
}

// MARK: - Address Suggestions

extension ComposeTableViewController {
    private final func updateSuggestTable() {
        var pos = ComposeHelpers.defaultCellHeight
        if pos < ComposeHelpers.defaultCellHeight && !isInitialSetup {
            pos = ComposeHelpers.defaultCellHeight * (ComposeHelpers.defaultCellHeight + 1) + 2
        }
        suggestionsChildViewController?.view.frame.origin.y = pos
        suggestionsChildViewController?.view.frame.size.height =
            tableView.bounds.size.height - pos + 2
    }

    private func hideSuggestions() {
        suggestionsChildViewController?.view.isHidden = true
    }

    private func showSuggestions() {
        suggestionsChildViewController?.view.isHidden = false
    }
}

// MARK: - UITableViewDataSource

extension ComposeTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return 0
        }
        return vm.sections.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return 0
        }
        return vm.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = setupCellForIndexPath(indexPath, in: tableView)
        return cell!
    }

    private func setupCellForIndexPath(_ indexPath: IndexPath,
                                  in tableView: UITableView) -> UITableViewCell? {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return UITableViewCell()
        }

        var result: UITableViewCell?
        let section = vm.sections[indexPath.section]

        if section.type == .recipients {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCell.reuseId)
                    as? RecipientCell,
                let rowVm = section.rows[indexPath.row] as? RecipientCellViewModel
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            result = cell
        } else if section.type == .wrapped {
            result = tableView.dequeueReusableCell(withIdentifier: "WrappedCell")
        } else if section.type == .account {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell_mvvm.reuseId)
                    as? AccountCell_mvvm,
                let rowVm = section.rows[indexPath.row] as? AccountCellViewModel
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            result = cell
        } else if section.type == .subject {
                guard
                    let cell = tableView.dequeueReusableCell(withIdentifier: SubjectCell.reuseId)
                        as? SubjectCell,
                    let rowVm = section.rows[indexPath.row] as? SubjectCellViewModel
                    else {
                        Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                    return nil
            }
            cell.setup(with: rowVm)
            result = cell
        }


//        else if section.type == .body {
//            guard
//                let cell = tableView.dequeueReusableCell(withIdentifier: BodyCell.reuseId)
//                    as? BodyCell,
//                let rowVm = section.rows[indexPath.row] as? BodyFieldViewModel
//                else {
//                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
//                    return nil
//            }
//            cell.textView.attributedText = rowVm.content
//            result = cell
//        } else if section.type == .attachments {
//            guard
//                let cell = tableView.dequeueReusableCell(withIdentifier: AttachmentCell.reuseId)
//                    as? AttachmentCell,
//                let rowVm = section.rows[indexPath.row] as? AttachmentViewModel
//                else {
//                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
//                    return nil
//            }
//            cell.fileName.text = rowVm.fileName
//            cell.fileExtension.text = rowVm.fileExtension
//            result = cell
//        }

        return result
    }
}

// MARK: - UITableViewDelegate

extension ComposeTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel?.handleUserSelectedRow(at: indexPath)
    }
}
