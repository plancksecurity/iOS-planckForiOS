//
//  pEpHeaderView.swift
//  pEp
//
//  Created by Adam Kowalski on 17/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class PEPHeaderView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "pEp Section Header"

    private struct Constant {
        struct Margin {
            static let top: CGFloat = 36
            static let bottom: CGFloat = 12
        }
    }

    private let titleLabel = UILabel()
    // numberOfLines property of the contained UILabel. See UILabel docs for details.
    public var numberOfLines = 0 {
        didSet {
            titleLabel.numberOfLines = numberOfLines
        }
    }

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
}

// MARK: - Private

extension PEPHeaderView {
    private func setUp() {
        contentView.addSubview(titleLabel)
        setFont(titleLabel: titleLabel)
        setConstraints(titleLabel: titleLabel)
        titleLabel.numberOfLines = numberOfLines
    }
    private func setFont(titleLabel: UILabel) {
        titleLabel.textColor = .pEpGreyText
        titleLabel.font = .pepFont(style: .subheadline, weight: .regular)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    private func setConstraints(titleLabel: UILabel) {
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor,
                                            constant: Constant.Margin.top),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                               constant: -Constant.Margin.bottom)
        ])
    }
}
