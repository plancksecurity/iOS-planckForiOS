//
//  FingerprintTableViewController.swift
//  Trustwords
//
//  Created by Igor Vojinovic on 12/29/16.
//  Copyright © 2016 Igor Vojinovic. All rights reserved.
//

import UIKit

class FingerprintTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
    }
    
    // MARK: - TableView Datasource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - Actions

    @IBAction func trustwordsButtonTapped(_ sender: RoundedButton) {
       navigationController?.dismiss(animated: true, completion: nil)
    }
}
