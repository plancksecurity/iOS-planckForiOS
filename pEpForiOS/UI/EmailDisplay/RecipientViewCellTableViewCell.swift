//
//  RecipientViewCellTableViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientViewCellTableViewCell: UITableViewCell {
    var message: Message! {
        didSet {
            labelContainerView?.message = self.message
        }
    }

    let kHorizontalInsets: CGFloat = 2.0
    let kVerticalInsets: CGFloat = 2.0

    var didSetupConstraints = false
    var labelContainerView: RecipientView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    func setupViews() {
        self.labelContainerView = RecipientView.newAutoLayoutView()
        contentView.addSubview(labelContainerView)
        setupConstraints()
    }

    func setupConstraints() {
        if !didSetupConstraints {
            // Prevent from being compressed below their intrinsic content height
            NSLayoutConstraint.autoSetPriority(UILayoutPriorityRequired) {
                labelContainerView.autoSetContentCompressionResistancePriorityForAxis(
                    .Vertical)
            }

            labelContainerView.autoPinEdgeToSuperviewEdge(.Top, withInset: kVerticalInsets)
            labelContainerView.autoPinEdgeToSuperviewEdge(.Leading,
                                                          withInset: kHorizontalInsets)
            labelContainerView.autoPinEdgeToSuperviewEdge(.Trailing,
                                                          withInset: kHorizontalInsets)

            didSetupConstraints = true
        }

        super.updateConstraints()
    }

    override func intrinsicContentSize() -> CGSize {
        var size = labelContainerView.intrinsicContentSize()
        size.height = size.height + 2 * kVerticalInsets
        size.width = size.width + 2 * kHorizontalInsets
        return size
    }
}