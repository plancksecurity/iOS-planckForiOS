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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if account == nil {
            textView.text = accounts.first?.user.address
        }
    }
    
    public func togglePicker() {
        picker.isHidden = !isExpanded && accounts.count > 1
    }
    
    // MARK: UIPickerView Delegate & Datasource
    
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
