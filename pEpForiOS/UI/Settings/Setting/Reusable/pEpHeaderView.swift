//
//  pEpHeaderView.swift
//  pEp
//
//  Created by Adam Kowalski on 17/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class pEpHeaderView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "pEp Section Header"

    private struct Constant {
        struct Margin {
            static let top: CGFloat = 36
            static let bottom: CGFloat = 12
        }
    }

    private let titleLabel = UILabel()

    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setUp()
    }

    private func setUp() {
        contentView.addSubview(titleLabel)
        titleLabel.textColor = .pEpGreyText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo:
                   contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor, constant: Constant.Margin.top),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -Constant.Margin.bottom)
        ])
    }
}
