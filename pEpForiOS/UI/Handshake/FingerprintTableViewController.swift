//
//  FingerprintTableViewController.swift
//  Trustwords
//
//  Created by Igor Vojinovic on 12/29/16.
//  Copyright © 2016 Igor Vojinovic. All rights reserved.
//

import UIKit
import MessageModel

class FingerprintTableViewController: UITableViewController {
   
    @IBOutlet weak var partnerNameLabel: UILabel!
    @IBOutlet weak var partnerFingerprintLabel: UILabel!
    @IBOutlet weak var mySelfNameLabel: UILabel!
    @IBOutlet weak var mySelfFingerprintLabel: UILabel!
    @IBOutlet weak var trustwordsButton: UIButton!

    var message: Message!
    var appConfig: AppConfig!
    var partnerIdentity: Identity!
    var myselfIdentity: Identity!
    var selectedTrustwordsLanguage: TrustwordsLanguage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        configureUI()
        setFingerprints()
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
    }
    
    func configureUI() {
        partnerNameLabel.text = partnerIdentity.displayString
        mySelfNameLabel.text = myselfIdentity.displayString
    }
    
    func setFingerprints() {
        if let myselfFingerprints = PEPUtil.fingerPrint(identity: myselfIdentity) {
            mySelfFingerprintLabel.text = fingerprintFormat(myselfFingerprints)
        }
        else {
            mySelfFingerprintLabel.text = ""
        }
        
        if let partnerFingerprints = PEPUtil.fingerPrint(identity: partnerIdentity) {
            partnerFingerprintLabel.text = fingerprintFormat(partnerFingerprints)
        }
        else {
            partnerFingerprintLabel.text = ""
        }
    }
    
    // MARK: - TableView Datasource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - Actions

    @IBAction func trustwordsButtonTapped(_ sender: RoundedButton) {
       navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmFingerprintButtonTapped(_ sender: RoundedButton) {
        PEPUtil.trust(identity: partnerIdentity)
    }
    
    @IBAction func wrongFingerprintButtonTapped(_ sender: RoundedButton) {
        PEPUtil.mistrust(identity: partnerIdentity)
    }
    
}

extension FingerprintTableViewController {
    
    func fingerprintFormat(_ fingerprint: String) -> String {
        let medio = fingerprint.characters.count/2
        var result = String()
        var cont = 0
        for character in fingerprint.characters {
            cont += 1
            result.append(character)
            if cont % 4 == 0 {
                result.append(" " as Character)
                result.append(" " as Character)
            }
            if cont == medio {
                result.append("\n" as Character)
            }
        }
        return result
    }
}
