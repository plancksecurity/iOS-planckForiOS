//
//  AccountCell.swift
//
//  Created by Yves Landert on 12.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit
import MessageModel

class AccountCell: ComposeCell {

    func setAccount(address: String) {
        self.textView.text = address

        guard let fm = super.fieldModel else {
            return
        }
        delegate?.composeCell(cell: self, didChangeEmailAddresses: [address], forFieldType: fm.type)
    }
}
