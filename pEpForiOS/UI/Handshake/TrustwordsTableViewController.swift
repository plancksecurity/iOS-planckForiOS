//
//  TrustwordsTableViewController.swift
//  Trustwords
//
//  Created by Igor Vojinovic on 12/29/16.
//  Copyright © 2016 Igor Vojinovic. All rights reserved.
//

import UIKit
import MessageModel
import ServerConfig

class TrustwordsTableViewController: UITableViewController {
    @IBOutlet weak var fingerprintButton: UIButton!
    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var languagePickerHeight: NSLayoutConstraint!
    @IBOutlet weak var trustwordsLanaguageLabel: UILabel!
    @IBOutlet weak var longTrustwordsSwitch: UISwitch!
    @IBOutlet weak var myEmailLabel: UILabel!
    @IBOutlet weak var partnerEmailLabel: UILabel!
    @IBOutlet weak var trustwordsLabel: UILabel!

    var message: Message!
    var appConfig: AppConfig!
    var partnerIdentity: Identity!
    var myselfIdentity: Identity!
    var selectedTrustwordsLanguage: TrustwordsLanguage!
    
    fileprivate let pickerHeight = 135.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        configureUI()
        setInitialLanguage()
        //setTrustwords()
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = 44.0
    }
    
    func configureUI() {
        //needs isPGPUser() and here you hide fingerprintButton
        myEmailLabel.text = myselfIdentity.displayString
        partnerEmailLabel.text = partnerIdentity.displayString
    }
    
    func setInitialLanguage() {
        let systemLangCode = PEPUtil.systemLanguage()
        for language in PEPUtil.trustwordsLanguages() {
            if language.languageCode == systemLangCode {
                selectedTrustwordsLanguage = language
                trustwordsLanaguageLabel.text = language.languageName
            }
        }
    }
    
    func setTrustwords(long: Bool = false) {
        let myselfContactPepContact = NSMutableDictionary(dictionary: myselfIdentity.pEpIdentity())
        let partnerPepContact = NSMutableDictionary(dictionary: partnerIdentity.pEpIdentity())
        appConfig.session.updateIdentity(myselfContactPepContact)
        appConfig.session.updateIdentity(partnerPepContact)
        if let trustWordsString = PEPUtil.trustwords(
            identity1: myselfContactPepContact.pEpIdentity(),
            identity2: partnerPepContact.pEpIdentity(),
            language: selectedTrustwordsLanguage.languageCode, full: long){
            trustwordsLabel.text = trustWordsString
        }
        else {
            trustwordsLabel.text = ""
        }
        
    }

    // MARK: - TableView Datasource

    override func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - Tableview delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            togglePicker(indexPath: indexPath)
        }
    }

    func togglePicker(indexPath: IndexPath) {
        if languagePickerHeight.constant == 0 {
            tableView .scrollToRow(at: indexPath, at: .top, animated: true)
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
    
    @IBAction func toggleLongTrustwords(_ sender: UISwitch) {
        setTrustwords(long: sender.isOn)
        tableView.reloadData()
    }
    
    @IBAction func confirmTrustwordsTapped(_ sender: UIButton) {
        PEPUtil.trust(identity: partnerIdentity)
    }
    
    @IBAction func wrongTrustwordsTapped(_ sender: UIButton) {
        PEPUtil.mistrust(identity: partnerIdentity)
    }
}

extension TrustwordsTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return PEPUtil.trustwordsLanguages().count
    }
    
    func pickerView(
        _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let language = PEPUtil.trustwordsLanguages()[row]
        return language.languageName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let language = PEPUtil.trustwordsLanguages()[row]
        selectedTrustwordsLanguage = language
        trustwordsLanaguageLabel.text = language.languageName
        setTrustwords(long: longTrustwordsSwitch.isOn)
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
        let navigationController = segue.destination
        let destination = navigationController.childViewControllers[0]
            as! FingerprintTableViewController
        destination.myselfIdentity = myselfIdentity
        destination.message = message
        destination.appConfig = appConfig
        destination.partnerIdentity = partnerIdentity
        destination.selectedTrustwordsLanguage = selectedTrustwordsLanguage
    }
}

