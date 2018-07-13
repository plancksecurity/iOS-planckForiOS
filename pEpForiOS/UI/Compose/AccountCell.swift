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

    var pickerEmailAdresses = [String]()

    public var shouldDisplayPicker: Bool = false {
        didSet {
            picker.isHidden = !shouldDisplayPicker
        }
    }

    // MARK: - Public Methods
    
    public final func expand() {
            shouldDisplayPicker = !shouldDisplayPicker
            isExpanded = shouldDisplayPicker
    }

    override func shouldDisplay() -> Bool {
        return pickerEmailAdresses.count > 1
    }

    // MARK: - UIPickerView Delegate & Datasource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerEmailAdresses.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerEmailAdresses[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let address = pickerEmailAdresses[row]
        textView.text = address

        guard let fm = super.fieldModel else {
            return
        }
        delegate?.composeCell(cell: self, didChangeEmailAddresses: [address], forFieldType: fm.type)
    }
}
