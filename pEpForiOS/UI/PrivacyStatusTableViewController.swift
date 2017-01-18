//
//  PrivacyStatusTableViewController.swift
//  Trustwords
//
//  Created by Igor Vojinovic on 12/28/16.
//  Copyright © 2016 Igor Vojinovic. All rights reserved.
//

import UIKit
import MessageModel

class PrivacyStatusTableViewController: UITableViewController {

    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var suggestionLabel: UILabel!
    
    var message: Message!
    var appConfig: AppConfig!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        updateLabelsText()
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
    }
    
    func updateLabelsText() {
        explanationLabel.text = "This message is secure but you still need to verify the identity of your communication partner."
        suggestionLabel.text = "Complete a handshake with your communication partner. A handshake is needed only once per partner and will ensure secure and trusted communication."
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension PrivacyStatusTableViewController: SegueHandlerType {
    
    // MARK: - SegueHandlerType
    
    enum SegueIdentifier: String {
        case noSegue
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
