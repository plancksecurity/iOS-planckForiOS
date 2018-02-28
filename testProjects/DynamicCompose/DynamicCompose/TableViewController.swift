//
//  TableViewController.swift
//  DynamicCompose
//
//  Created by Dirk Zimmermann on 28.02.18.
//  Copyright © 2018 pEp Security AG. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
    }

    public final func updateSize() {
        print("\(#function)")
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        updateSize()
    }
}

extension TableViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSize()
    }
}
