//
//  ViewController.swift
//  AutoSizingTableView
//
//  Created by Dirk Zimmermann on 15.10.19.
//  Copyright © 2019 pEp Security. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableView.automaticDimension
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TheCell",
                                                    for: indexPath) as? Cell {
            var content = ""
            for i in 0...indexPath.row {
                if i > 0 {
                    content += "\n\n"
                }
                content += "TextLabel Nr. \(indexPath.row) (\(i))\n\n"
                content += "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Adipiscing bibendum est ultricies integer quis auctor elit sed vulputate."
            }
            cell.theTextLabel.text = content
            return cell
        }

        return UITableViewCell()
    }
}
