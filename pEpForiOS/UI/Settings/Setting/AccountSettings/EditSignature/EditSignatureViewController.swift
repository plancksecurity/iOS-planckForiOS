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
    public var viewModel: EditSignatureViewModel?

    override func viewDidLoad() {
        setup()
    }
    
    func setup() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let newSignature = getSignature() else {
            return
        }
        viewModel?.updateSignature(newSignature: newSignature)
    }
    
    func getSignature() -> String? {
        let presentedCellIndexPaht = IndexPath(row: 0, section: 0)
        guard let cell = tableView.cellForRow(at: presentedCellIndexPaht) as? SignatureTableViewCell else {
            return nil
        }
        return cell.editableSignature.text
    }
}

extension EditSignatureViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.numberOfRows ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SignatureCell") as? SignatureTableViewCell else {
            return UITableViewCell()
        }
        cell.editableSignature.text = viewModel?.actualSignature()
        return cell
    }
    
    
    
}
