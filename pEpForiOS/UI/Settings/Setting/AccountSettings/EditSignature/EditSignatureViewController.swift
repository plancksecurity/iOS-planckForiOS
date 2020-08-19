//
//  EditSignatureViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 12/08/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class EditSignatureViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    var viewModel: EditSignatureViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
    }
}

extension EditSignatureViewController: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.numberOfRows ?? 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    private func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "blah"
        return cell
    }
    
    
}
