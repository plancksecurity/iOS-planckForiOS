//
//  ThreadViewController+EmailViewControllerDelegate.swift
//  pEp
//
//  Created by Borja González de Pablo on 18/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
extension ThreadViewController: EmailViewModelDelegate {

    func emailViewModel(viewModel: ThreadedEmailViewModel, didInsertDataAt index: Int) {
        updateTableView {
            tableView.insertSections(IndexSet([index]), with: .automatic)
        }
    }

    func emailViewModel(viewModel: ThreadedEmailViewModel, didUpdateDataAt index: Int) {
        updateTableView {
            tableView.reloadSections(IndexSet([index]), with: .none)
        }
    }

    func emailViewModel(viewModel: ThreadedEmailViewModel, didRemoveDataAt index: Int) {
        updateTableView {
            tableView.deleteSections(IndexSet([index]), with: .automatic)
        }
    }

    func updateView() {
        tableView.dataSource = self
        tableView.reloadData()
    }

    private func updateTableView(updates: ()->()) {
        tableView.beginUpdates()
        updates()
        tableView.endUpdates()
    }
    

}
