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

extension ComposeTableViewController {
    class Row {
        let title: String? = nil
        let content: NSAttributedString? = nil
    }

    class Section {

    }
}

class ComposeTableViewController: BaseTableViewController {
    @IBOutlet var sendButton: UIBarButtonItem!

    var isInitialSetup = true
    var composeMode = ComposeUtil.ComposeMode.normal
    private var currentCellIndexPath: IndexPath?


    var viewModel: ComposeViewModel? {
        didSet {
            // Make sure we are the delegate. Always.
            viewModel?.delegate = self
        }
    }

    private var suggestionsChildViewController: SuggestTableViewController?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupModel()
    }

    // MARK: - Setup & Configuration

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
    func userSelectedRecipient(identity: Identity) {
        guard
            let indexPath = currentCellIndexPath,
            let cell = tableView.cellForRow(at: indexPath) as? RecipientCell else {
                Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
                return
        }
        hideSuggestions()
        cell.addIdentity(identity)
        cell.textView.scrollToTop()
        suggestionsChildViewController?.tableView.updateSize()
    }

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
