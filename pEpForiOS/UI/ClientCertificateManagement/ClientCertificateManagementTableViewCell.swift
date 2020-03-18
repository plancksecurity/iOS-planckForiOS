//
//  ClientCertificateManagementTableViewCell.swift
//  pEp
//
//  Created by Adam Kowalski on 02/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import SwipeCellKit

final class ClientCertificateManagementTableViewCell: PEPSwipeTableViewCell {

    static public let reusableId = "ClientCertificateManagementTableViewCell"

    @IBOutlet weak private var titleLabel: UILabel?
    @IBOutlet weak private var dateLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupStyle()
    }

    /// fill labels with data
    public func setData(title: String, date: String) {
        titleLabel?.text = title
        dateLabel?.text = date
    }
}

// MARK: - Private

extension ClientCertificateManagementTableViewCell {
    private func setupStyle() {
        titleLabel?.font = .pepFont(style: .title2, weight: .regular)
        titleLabel?.textColor = .pEpGreen
        dateLabel?.font = .pepFont(style: .footnote, weight: .regular)
        dateLabel?.textColor = .pEpGreen
    }
}
