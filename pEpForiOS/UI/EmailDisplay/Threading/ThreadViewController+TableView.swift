//
//  ThreadViewController+TableView.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 05/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension ThreadViewController: UITableViewDelegate, UITableViewDataSource {


    func numberOfSections(in tableView: UITableView) -> Int {
        return model?.rowCount() ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fullyDisplayedSections[section] == true {
            return 3
        }
        else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if fullyDisplayedSections[indexPath.section] == true {
            return UITableViewAutomaticDimension
        }
        else {
            return 100
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if fullyDisplayedSections[indexPath.section] == true {
            return expandedCell(tableView, cellForRowAt:indexPath)
        }
        else {
            return unexpandedCell(tableView, cellForRowAt:indexPath)
        }
    }

    func unexpandedCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "unexpandedCell") as? EmailListViewCell else {
            return UITableViewCell()
        }
        let row = model?.row(for: indexPath.section)
        cell.addressLabel.text = row?.from
        cell.subjectLabel.text = row?.subject
        cell.summaryLabel.text = row?.bodyPeek
        cell.backgroundColor = UIColor.clear

        return cell

    }

    func expandedCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {

        }
        return UITableViewCell()
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if fullyDisplayedSections[indexPath.section] == false {
            fullyDisplayedSections[indexPath.section] = true
            let indexSet = IndexSet(integer: indexPath.section)
            tableView.reloadSections(indexSet, with: .automatic)
        }
    }

}
