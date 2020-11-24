//
//  MessageCell.swift
//
//  Created by Yves Landert on 16.12.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {
    @IBOutlet weak public var titleLabel: UILabel?
    @IBOutlet weak public var valueLabel: UILabel?

    override open func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
}
