//
//  LanguageListViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class LanguageListViewController: BaseTableViewController {
    let defaultCellReuseIdentifier = "LanguageListCell"

    var languages = [PEPLanguage]()
    var chosenLanguage: PEPLanguage?

    override func awakeFromNib() {
        tableView.estimatedRowHeight = 44.0
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
        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellReuseIdentifier,
                                                 for: indexPath)
        guard let theCell = cell as? LanguageListTableViewCell else {
            return cell
        }

        let lang = languages[indexPath.row]
        theCell.sentenceLabel.text = lang.sentence
        theCell.languageLabel.text = lang.name

        return cell
    }
}

extension LanguageListViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case selectedLanguageSegue
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .selectedLanguageSegue:
            if let indexPath = tableView.indexPathForSelectedRow {
                chosenLanguage = languages[indexPath.row]
            } else {
                chosenLanguage = nil
            }
            break
        }
    }
}
