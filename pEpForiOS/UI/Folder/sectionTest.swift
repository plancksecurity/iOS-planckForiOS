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
    var delegate: CollapsibleTableViewHeaderDelegate?
    var section: Int = 0
    var collapsed: Bool = true

    let topStackView = UIStackView()
    let labelStackView = UIStackView()
    let profileImage = UIImageView()
    let accountType = UILabel()
    let accountName = UILabel()
    let userAddress = UILabel()
    let rightStackView = UIStackView()
    let arrowImageView = UIImageView()
    let arrowLabel = UILabel()
    //let clicableView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        profileImage.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        profileImage.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        //profileImage.addConstraint(NSLayoutConstraint.init(item: profileImage, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: profileImage, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0))

        arrowImageView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        rightStackView.widthAnchor.constraint(equalToConstant: 10).isActive = true

        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.addArrangedSubview(arrowImageView)
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


        //topStackView.addArrangedSubview(profileImage)
        //topStackView.addArrangedSubview(labelStackView)
        //topStackView.addArrangedSubview(rightStackView)
        //topStackView.axis = .horizontal
        //topStackView.alignment = .fill
        //topStackView.distribution = .fill
        //topStackView.translatesAutoresizingMaskIntoConstraints = false
        //contentView.addSubview(topStackView)
        contentView.addSubview(profileImage)
        contentView.addSubview(rightStackView)
        contentView.addSubview(labelStackView)

        contentView.backgroundColor = UIColor.white
        //clicableView.backgroundColor = UIColor.clear

        //contentView.addSubview(clicableView)
        autolayout()

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CollapsibleTableViewHeader.tapHeader(gestureRecognizer:))))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: FolderSectionViewModel, section: Int) {
        self.accountName.text = viewModel.userName
        self.accountType.text = viewModel.type
        self.userAddress.text = viewModel.userAddress
        self.profileImage.image = UIImage(named: "swipe-trash")
        self.arrowImageView.image = UIImage(named:"chevron-icon")
        self.section = section
        collapsed = viewModel.collapsed
        arrowImageView.transform = arrowImageView.transform.rotated(by: CGFloat.pi/2)
    }

    func autolayout() {

        contentView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-10-[profileImage]-5-[labelstackview]-[rightstackview]-15-|",
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil,
            views: ["profileImage" : profileImage, "labelstackview" : labelStackView, "rightstackview" : rightStackView ]
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
        profileImage.layer.cornerRadius = profileImage.bounds.size.height / 2
        profileImage.layer.masksToBounds = true
    }

    //
    // Trigger toggle section when tapping on the header
    //
    func tapHeader(gestureRecognizer: UITapGestureRecognizer) {
        guard let cell = gestureRecognizer.view as? CollapsibleTableViewHeader else {
            return
        }
        if !collapsed {
            arrowImageView.transform = arrowImageView.transform.rotated(by: CGFloat.pi/2)
        } else {
            arrowImageView.transform = arrowImageView.transform.rotated(by: -(CGFloat.pi/2))
        }
        collapsed = !collapsed
        delegate?.toggleSection(header: self, section: cell.section)

    }

    func setCollapsed(collapsed: Bool) {
        //
        // Animate the arrow rotation (see Extensions.swf)
        //
        //arrowLabel.rotate(toValue: collapsed ? 0.0 : CGFloat(M_PI_2))
    }

}
