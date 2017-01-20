//
//  TrustwordsTableViewController.swift
//  Trustwords
//
//  Created by Igor Vojinovic on 12/29/16.
//  Copyright © 2016 Igor Vojinovic. All rights reserved.
//

import UIKit
import MessageModel

class TrustwordsTableViewController: UITableViewController {

    @IBOutlet weak var fingerprintButton: RoundedButton!
    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var languagePickerHeight: NSLayoutConstraint!
    
    var message: Message!
    var appConfig: AppConfig!
    
    fileprivate let pickerHeight = 135.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        configureUI()
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
    }
    
    func configureUI() {
        //needs isPGPUser() and here you hide fingerprintButton
    }

    // MARK: - TableView Datasource

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - Tableview delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            togglePicker()
        }
    }

    func togglePicker() {
        if languagePickerHeight.constant == 0 {
            showLangPicker()
        }
        else {
            hideLangPicker()
        }
    }
    
    func showLangPicker() {
        languagePickerHeight.constant = 135.0
        animateTable()
    }
    
    func hideLangPicker() {
        languagePickerHeight.constant = 0.0
        animateTable()
    }
    
    func animateTable() {
        tableView.updateSize()
    }
    
    // MARK: - Actions

    @IBAction func fingerprintButtonTapped(_ sender: RoundedButton) {
        performSegue(withIdentifier: "segueFingerprint", sender: self)
    }
}

extension TrustwordsTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 5
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Row - \(row)"
    }
}

extension TrustwordsTableViewController: SegueHandlerType {
    
    // MARK: - SegueHandlerType
    
    enum SegueIdentifier: String {
        case segueFingerprint
        case noSegue
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
}

