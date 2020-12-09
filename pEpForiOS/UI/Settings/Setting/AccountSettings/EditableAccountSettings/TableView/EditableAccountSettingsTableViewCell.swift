//
//  EditableAccountSettingsTableViewCell.swift
//  pEp
//
//  Created by Martín Brude on 9/12/20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class EditableAccountSettingsTableViewCell: UITableViewCell {

    public static let identifier = "EditableAccountSettingsTableViewCell"

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
