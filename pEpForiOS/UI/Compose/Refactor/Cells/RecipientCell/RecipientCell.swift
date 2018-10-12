//
//  RecipientCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientCell: TextViewContainingTableViewCell {
    static let reuseId = "RecipientCell"
    var viewModel: RecipientCellViewModel?
    @IBOutlet weak public var titleLabel: UILabel!
}

