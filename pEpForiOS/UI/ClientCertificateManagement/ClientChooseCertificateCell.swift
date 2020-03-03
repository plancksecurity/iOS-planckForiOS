//
//  ClientChooseCertificateCell.swift
//  pEp
//
//  Created by Adam Kowalski on 02/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class ClientChooseCertificateCell: UITableViewCell {

    static let reusableId = "ClientChooseCertificateCell"

    @IBOutlet weak var titleLabel: UILabel?
//    @IBOutlet weak var dateLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    func setup() {
        titleLabel?.font = .pepFont(style: .title2, weight: .regular)
        titleLabel?.textColor = .pEpGreen

//        dateLabel?.text = ""
//        backgroundColor = .white
    }
}
