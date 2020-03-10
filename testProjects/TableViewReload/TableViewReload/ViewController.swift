//
//  ViewController.swift
//  TableViewReload
//
//  Created by Dirk Zimmermann on 16.01.19.
//  Copyright © 2019 pEp Security AG. All rights reserved.
//

import UIKit

class Model {
    var shouldIncrease = true
    var numRows = 6
}

class ViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
            self.changeModel()
        }
    }

    func changeModel() {
        if model.shouldIncrease {
            model.numRows += 1
        } else {
            model.numRows -= 1
        }
        model.shouldIncrease = !model.shouldIncrease
        (view as! UITableView).reloadData()
    }

    // MARK: - UITableViewDataSource

    let model = Model()

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return model.numRows
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "the_cell_id"

        if indexPath.row >= model.numRows {
            print("*** ERROR")
        }

        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
            cell.textLabel?.text = "\(indexPath.row)"
            return cell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
            cell.textLabel?.text = "ERROR: Wrong section"
            return cell
        }
    }
}
