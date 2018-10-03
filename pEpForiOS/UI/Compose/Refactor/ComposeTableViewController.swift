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
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet var sendButton: UIBarButtonItem!

    // MARK: - IOS-1369 BRAND NEW SHIT

    var viewModel: ComposeViewModel? {
        didSet {
            // Make sure we are the delegate. Always.
            viewModel?.delegate = self
        }
    }

    private var suggestionsChildViewController: SuggestTableViewController?

    // MARK: - Setup & Configuration

    private func setupModel() {
        viewModel = ComposeViewModel(delegate: self)
    }

    private final func setupRecipientSuggestionsTableViewController() {
        guard
            let vm = viewModel,
            let suggestVc = SuggestSceneConfigurator.suggestTableViewController(resultDelegate: vm),
            let suggestView = suggestVc.view else {
                Log.shared.errorAndCrash(component: #function, errorString: "No VC.")
                return
        }
        suggestionsChildViewController = suggestVc
        addChildViewController(suggestVc)
        suggestView.isHidden = true
        updateSuggestTable(defaultCellHeight)
        tableView.addSubview(suggestView)
    }

    // MARK: - Address Suggestions

    private func hideSuggestions() {
        suggestionsChildViewController?.view.isHidden = true
    }

    private func showSuggestions() {
        suggestionsChildViewController?.view.isHidden = false
    }
}

// MARK: - IOS-1369 BRAND NEW SHIT

extension ComposeTableViewController: ComposeViewModelDelegate {
    //IOS-1369: tmp. has to change. The receiver ComposeVC must not know Identity
    func userSelectedRecipient(identity: Identity) {
        guard let cell = tableView.cellForRow(at: currentCellIndexPath) as? RecipientCell else {
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

// MARK: - IOS-1369 TIHS WEN DNARB
