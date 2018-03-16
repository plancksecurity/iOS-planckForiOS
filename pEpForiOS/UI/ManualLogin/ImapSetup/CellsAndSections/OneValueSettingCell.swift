//
//  MyTableViewCustomCell.swift
//  pEpDemo
//
//  Created by ana on 12/4/16.
//  Copyright © 2016 pEp. All rights reserved.
//

import UIKit

class OneValueSettingCell: UITableViewCell {

    @IBOutlet weak var titleName: UILabel!
    @IBOutlet weak var fieldName: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
