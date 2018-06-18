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
        return 1
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
            return configureCell(identifier: "expandedCell", at: indexPath)
        }
        else {
            return configureCell(identifier: "unexpandedCell", at: indexPath)
        }
    }

    func configureCell(identifier:String, at indexPath:IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? UITableViewCell&MessageViewModelConfigurable,
            let viewModel = model?.viewModel(for: indexPath.section)  else {
                return UITableViewCell()
        }
        cell.configure(for: viewModel)
        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if fullyDisplayedSections[indexPath.section] == false {
            fullyDisplayedSections[indexPath.section] = true
            let indexSet = IndexSet(integer: indexPath.section)
            tableView.reloadSections(indexSet, with: .automatic)
        }
        else {
            performSegue(withIdentifier: .segueShowEmail, sender: self)
        }
    }

}
