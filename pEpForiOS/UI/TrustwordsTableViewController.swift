//
//  TrustwordsTableViewController.swift
//  Trustwords
//
//  Created by Igor Vojinovic on 12/29/16.
//  Copyright © 2016 Igor Vojinovic. All rights reserved.
//

import UIKit

class TrustwordsTableViewController: UITableViewController {

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

    @IBAction func fingerprintButtonTapped(_ sender: RoundedButton) {
        performSegue(withIdentifier: "segueTrustwords", sender: self)
    }
}
