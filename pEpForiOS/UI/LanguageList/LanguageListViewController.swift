//
//  LanguageListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class LanguageListViewController: UITableViewController {
    let defaultCellReuseIdentifier = "LanguageListCell"

    var languages = [PEPLanguage]()

    override func awakeFromNib() {
        tableView.estimatedRowHeight = 72.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellReuseIdentifier) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: defaultCellReuseIdentifier)

        let lang = languages[indexPath.row]
        cell.textLabel?.text = lang.sentence
        cell.detailTextLabel?.text = lang.name

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let lang = languages[indexPath.row]
    }
}
