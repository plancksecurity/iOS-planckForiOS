//
//  AccountCell.swift
//
//  Created by Yves Landert on 12.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

class AccountCell: ComposeCell, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var picker: UIPickerView!
    
    var accounts = Account.all()
    var account: String?
    
    public var shouldDisplayPicker: Bool = false {
        didSet {
            picker.isHidden = !shouldDisplayPicker
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if account == nil {
            account = accounts.first?.user.address
            textView.text = account
        }
    }
    
    // MARK: - Public Methods
    
    public final func expand() -> Bool {
        if isExpanded && !shouldDisplayPicker {
            shouldDisplayPicker = true
        } else {
            shouldDisplayPicker = false
            isExpanded = !isExpanded
            
            titleLabel?.text = fieldModel?.title
            
            if isExpanded {
                titleLabel?.text = fieldModel?.expandedTitle
            }
        }
        return isExpanded
    }
    
    public final func getAccount() -> Identity {
        let selected = picker.selectedRow(inComponent: 0)
        return accounts[selected].user
    }
    
    // MARK: - UIPickerView Delegate & Datasource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return accounts.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return accounts[row].user.address
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        textView.text = accounts[row].user.address
    }
}
