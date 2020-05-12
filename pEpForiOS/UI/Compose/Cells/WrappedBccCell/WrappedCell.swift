//
//  WrappedCell.swift
//  pEp
//
//  Created by Adam Kowalski on 13/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class WrappedCell: UITableViewCell {

    @IBOutlet weak private var ccBccLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setStyle()
    }

    private func setStyle() {
        ccBccLabel.font = UIFont.pepFont(style: .footnote, weight: .regular)
    }
}
