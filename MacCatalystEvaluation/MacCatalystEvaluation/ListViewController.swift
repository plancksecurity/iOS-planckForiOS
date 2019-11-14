//
//  ListViewController.swift
//  MacCatalystEvaluation
//
//  Created by Andreas Buff on 13.11.19.
//  Copyright © 2019 pEp. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController {
//    let data = [Int](1...100).map { "\($0)" }
    let data = [[Int](1...100).map { "\($0)" }, [Int](200...299).map { "\($0)" }]

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell", for: indexPath)

        cell.textLabel?.text = data(for: indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        if section == 0 {
            view.backgroundColor = UIColor.green
        } else {
            view.backgroundColor = UIColor.red
        }
        return view
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = (UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "DetailViewController")) as! DetailViewController
        splitViewController?.showDetailViewController(detailVC, sender: self)
        detailVC.label.text = data(for: indexPath)
    }

    // MARK: - PRIVATE

    private func data(for indexPath: IndexPath) -> String {
        return data[indexPath.section][indexPath.row]
    }
}
