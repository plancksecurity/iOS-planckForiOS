//
//  pEpFooterView.swift
//  pEp
//
//  Created by Martin Brude on 22/04/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class pEpFooterView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "pEp Section Footer"

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
        setup()
    }
}

// MARK: - Private

extension pEpFooterView {
    
    private func setup() {
        contentView.backgroundColor = .groupTableViewBackground
        contentView.addSubview(titleLabel)
        configure(titleLabel: titleLabel)
        setFont(titleLabel: titleLabel)
        setConstraints(titleLabel: titleLabel)
    }

    private func configure(titleLabel: UILabel) {
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
    }

    private func setFont(titleLabel: UILabel) {
        titleLabel.textColor = .pEpGreyText
        titleLabel.font = .pepFont(style: .caption2, weight: .regular)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    private func setConstraints(titleLabel: UILabel) {
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }
}

