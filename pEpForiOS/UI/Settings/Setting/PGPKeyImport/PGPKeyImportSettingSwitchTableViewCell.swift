//
//  PGPKeyImportSettingSwitchTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 01/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

protocol PGPKeyImportSettingSwitchTableViewCellDelegate: class {
    func passphraseSwitchChanged(sender: PGPKeyImportSettingSwitchTableViewCell, didChangeSwitchValue newValue: Bool, cancelCallback: (() -> Void)?)
}

class PGPKeyImportSettingSwitchTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passphraseSwitch: UISwitch!
    weak var delegate: PGPKeyImportSettingSwitchTableViewCellDelegate?

    @IBAction func usePassphraseSwitchChanged(_ sender: UISwitch) {
        delegate?.passphraseSwitchChanged(sender: self, didChangeSwitchValue: sender.isOn,
                                          cancelCallback: { [weak self] in
                                            guard let me = self else {
                                                Log.shared.lostMySelf()
                                                return
                                            }
                                            me.passphraseSwitch.setOn(false, animated: true)
        })
    }
}
