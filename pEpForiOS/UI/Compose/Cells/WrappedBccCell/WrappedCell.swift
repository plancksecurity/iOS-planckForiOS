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
        setup()
    }

    private func setStyle() {
        ccBccLabel.font = UIFont.pepFont(style: .footnote, weight: .regular)
    }

    func setup() {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .light {
                backgroundColor = .white
            } else {
                backgroundColor = .secondarySystemBackground
            }
        } else {
            backgroundColor = .white
        }
    }
}
