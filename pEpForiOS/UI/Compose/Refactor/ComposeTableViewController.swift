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

    var isInitialSetup = true
    var composeMode = ComposeUtil.ComposeMode.normal
    private var currentCellIndexPath: IndexPath?


    var viewModel: ComposeViewModel? {
        didSet {
            // Make sure we are the delegate. Always.
            viewModel?.delegate = self
            tableView.reloadData()
        }
    }

    private var suggestionsChildViewController: SuggestTableViewController?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupModel()
    }

    // MARK: - Setup & Configuration

    private func setupView() {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 164 //IOS-1369 an arbitrary value that works well for subject
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

    /**
     Shows a menu where user can choose to make a handshake, or toggle force unprotected.
     */
    @IBAction func actionHandshakeOrForceUnprotected(gestureRecognizer: UITapGestureRecognizer) {
        //IOS-1369:
    }
}

extension ComposeTableViewController: ComposeViewModelDelegate {
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

    // WILL GROW!
}

// MARK: - Address Suggestions

extension ComposeTableViewController {
    private final func updateSuggestTable() {
        var pos = defaultCellHeight
        if pos < defaultCellHeight && !isInitialSetup {
            pos = defaultCellHeight * (defaultCellHeight + 1) + 2
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
/*
        if section.type == .recipients { //IOS-1369: inherit from TitleAndTextViewCell
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: RecipientCell.reuseId)
                    as? RecipientCell,
                let rowVm = section.rows[indexPath.row] as? RecipientFieldViewModel
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                    return nil
            }
            cell.titleLabel.text = rowVm.title
            cell.textView.attributedText = rowVm.content
            result = cell
        } else if section.type == .account {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell_mvvm.reuseId)
                    as? AccountCell_mvvm,
                let rowVm = section.rows[indexPath.row] as? AccountFieldViewModel
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                    return nil
            }
            cell.textView.attributedText = rowVm.content
            result = cell
        } else
*/
        if section.type == .subject {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: SubjectCell.reuseId)
                    as? SubjectCell,
                let rowVm = section.rows[indexPath.row] as? SubjectCellViewModel
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                    return nil
            }
            cell.textView.attributedText = rowVm.content//NSAttributedString(string: "IOS-1369: Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test Test ") //rowVm.content
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

//    override func tableView(_ tableView: UITableView,
//                            heightForRowAt indexPath: IndexPath) -> CGFloat {
//        guard let vm = viewModel else {
//            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
//            return 0.0
//        }
//        return vm.minimumCellHeight(forCellAt: indexPath)
//    }
}
