//
//  AddAccountTableViewCell.swift
//  pEp
//
//  Created by Martín Brude on 7/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

class AddAccountTableViewCell: UITableViewCell {
    @IBOutlet private weak var addAccountButton: UIButton!

    private var addAccountAction: NoActivatedAccountViewModel.ActionBlock?

    public func configure(row: NoActivatedAccountViewModel.ActionRow) {
        let title = NSLocalizedString("Add account", comment: "Add Account button title")
        addAccountButton.setTitle(title, for: .normal)
        addAccountAction = row.action
    }

    @IBAction private func addAccountButtonPressed() {
        addAccountAction?()
    }
}
