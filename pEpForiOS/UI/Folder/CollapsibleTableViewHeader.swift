//
//  sectionTest.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 29/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

protocol CollapsibleTableViewHeaderDelegate {
    func toggleSection(header: CollapsibleTableViewHeader, section: Int)
}

class CollapsibleTableViewHeader: UITableViewHeaderFooterView {
    var section: Int = 0

    let topStackView = UIStackView()
    let labelStackView = UIStackView()
    let profileImage = UIImageView()
    let accountType = UILabel()
    let accountName = UILabel()
    let userAddress = UILabel()
    let rightStackView = UIStackView()
    let arrowImageView = UIImageView()
    let arrowLabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        profileImage.widthAnchor.constraint(equalToConstant: 48.0).isActive = true
        profileImage.heightAnchor.constraint(equalToConstant: 48.0).isActive = true
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        //arrowImageView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        rightStackView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        //arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        //rightStackView.addArrangedSubview(arrowImageView)
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.addArrangedSubview(arrowLabel)
        rightStackView.axis = .vertical
        rightStackView.alignment = .fill
        rightStackView.distribution = .fill
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        accountType.translatesAutoresizingMaskIntoConstraints = false
        accountType.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        labelStackView.addArrangedSubview(accountType)
        accountName.translatesAutoresizingMaskIntoConstraints = false
        accountName.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        labelStackView.addArrangedSubview(accountName)
        userAddress.translatesAutoresizingMaskIntoConstraints = false
        userAddress.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        labelStackView.addArrangedSubview(userAddress)
        labelStackView.layoutMargins = UIEdgeInsets(top: 0.0, left: 5.0, bottom: 0.0, right: 5.0)
        labelStackView.isLayoutMarginsRelativeArrangement = true
        labelStackView.axis = .vertical
        labelStackView.alignment = .fill
        labelStackView.distribution = .fillEqually
        labelStackView.spacing = 5.0
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImage)
        contentView.addSubview(rightStackView)
        contentView.addSubview(labelStackView)
        contentView.backgroundColor = UIColor.white
        autolayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: FolderSectionViewModel, section: Int) {
        self.accountName.text = viewModel.userName
        self.accountType.text = viewModel.type
        self.userAddress.text = viewModel.userAddress
        viewModel.getImage { (imageProfile) in
            self.profileImage.image = imageProfile
        }
        self.arrowImageView.image = UIImage(named:"chevron-icon")
        self.arrowImageView.transform = arrowImageView.transform.rotated(by: CGFloat.pi/2)
        self.section = section
    }

    func autolayout() {

        contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-10-[profileImage]-5-[labelstackview]-[rightstackview]-15-|",
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: ["profileImage" : profileImage,
                    "labelstackview" : labelStackView,
                    "rightstackview" : rightStackView ]
        ))

        profileImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true

        contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-10-[stackView]-10-|",
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: ["stackView" : labelStackView ]
        ))

        contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-10-[stackView]-10-|",
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: ["stackView" : rightStackView ]
        ))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        profileImage.applyContactImageCornerRadius()
    }
}
