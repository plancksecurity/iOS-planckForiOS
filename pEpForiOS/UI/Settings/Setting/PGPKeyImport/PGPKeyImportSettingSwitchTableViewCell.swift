//
//  PGPKeyImportSettingSwitchTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 01/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol PGPKeyImportSettingSwitchTableViewCellDelegate: class {
    func passphraseSwitchChanged(sender: PGPKeyImportSettingSwitchTableViewCell, didChangeSwitchValue newValue: Bool)
    func passphraseSwitchChanged(sender: PGPKeyImportSettingSwitchTableViewCell, didChangeSwitchValue newValue: Bool, cancelCallback: (() -> Void)?)


}

class PGPKeyImportSettingSwitchTableViewCell: UITableViewCell {
   static let storyboardId = "PGPKeyImportSettingSwitchTableViewCell"
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var passphraseSwitch: UISwitch!
    weak var delegate: PGPKeyImportSettingSwitchTableViewCellDelegate?
    @IBAction func usePassphraseSwitchChanged(_ sender: UISwitch) {
        //        delegate?.passphraseSwitchChanged(sender: self, didChangeSwitchValue: sender.isOn)

        delegate?.passphraseSwitchChanged(sender: self, didChangeSwitchValue: sender.isOn,
                                          cancelCallback: { [weak self] in
                                            guard let me = self else {
                                                Log.shared.errorAndCrash("Lost myself")
                                                return
                                            }
                                            me.passphraseSwitch.setOn(false, animated: true)
        })
    }
}
