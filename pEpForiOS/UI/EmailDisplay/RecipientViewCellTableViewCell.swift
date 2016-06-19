//
//  RecipientViewCellTableViewCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientViewCellTableViewCell: UITableViewCell {
    var message: Message!

    let kHorizontalInsets: CGFloat = 2.0
    let kVerticalInsets: CGFloat = 2.0

    var didSetupConstraints = false
    var labelContainerView: LabelContainerView!

    let kLabelHorizontalInsets: CGFloat = 15.0
    let kLabelVerticalInsets: CGFloat = 10.0

    var titleLabel: UILabel = UILabel.newAutoLayoutView()
    var bodyLabel: UILabel = UILabel.newAutoLayoutView()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    func setupViews() {
        /*
        self.labelContainerView = LabelContainerView.newAutoLayoutView()
        contentView.addSubview(labelContainerView)

        var labels: [UILabel] = []
        for i in 1...20 {
            let label = UILabel.newAutoLayoutView()
            label.text = "Title \(i)"
            labels.append(label)
        }
        self.labelContainerView.labels = labels
         */
        titleLabel.lineBreakMode = .ByTruncatingTail
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .Left
        titleLabel.textColor = UIColor.blackColor()
        titleLabel.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.1) // light blue

        bodyLabel.lineBreakMode = .ByTruncatingTail
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .Left
        bodyLabel.textColor = UIColor.darkGrayColor()
        bodyLabel.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.1) // light red

        updateFonts()

        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)

        contentView.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.1) // light green

        titleLabel.text = "This is the title"
        bodyLabel.text = "This is the body"
    }

    override func updateConstraints() {
        /*
        if !didSetupConstraints {
            // Prevent from being compressed below their intrinsic content height
            NSLayoutConstraint.autoSetPriority(UILayoutPriorityRequired) {
                self.labelContainerView.autoSetContentCompressionResistancePriorityForAxis(
                    .Vertical)
            }

            self.labelContainerView.autoPinEdgeToSuperviewEdge(.Top, withInset: kVerticalInsets)
            self.labelContainerView.autoPinEdgeToSuperviewEdge(.Leading,
                                                               withInset: kHorizontalInsets)
            self.labelContainerView.autoPinEdgeToSuperviewEdge(.Trailing,
                                                               withInset: kHorizontalInsets)

            didSetupConstraints = true
        }

        super.updateConstraints()
         */
        if !didSetupConstraints {
            // Note: if the constraints you add below require a larger cell size than the current size (which is likely to be the default size {320, 44}), you'll get an exception.
            // As a fix, you can temporarily increase the size of the cell's contentView so that this does not occur using code similar to the line below.
            //      See here for further discussion: https://github.com/Alex311/TableCellWithAutoLayout/commit/bde387b27e33605eeac3465475d2f2ff9775f163#commitcomment-4633188
            // contentView.bounds = CGRect(x: 0.0, y: 0.0, width: 99999.0, height: 99999.0)

            // Prevent the two UILabels from being compressed below their intrinsic content height
            NSLayoutConstraint.autoSetPriority(UILayoutPriorityRequired) {
                self.titleLabel.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
                self.bodyLabel.autoSetContentCompressionResistancePriorityForAxis(.Vertical)
            }

            titleLabel.autoPinEdgeToSuperviewEdge(.Top, withInset: kLabelVerticalInsets)
            titleLabel.autoPinEdgeToSuperviewEdge(.Leading, withInset: kLabelHorizontalInsets)
            titleLabel.autoPinEdgeToSuperviewEdge(.Trailing, withInset: kLabelHorizontalInsets)

            // This constraint is an inequality so that if the cell is slightly taller than actually required, extra space will go here
            bodyLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: titleLabel, withOffset: 10.0, relation: .GreaterThanOrEqual)

            bodyLabel.autoPinEdgeToSuperviewEdge(.Leading, withInset: kLabelHorizontalInsets)
            bodyLabel.autoPinEdgeToSuperviewEdge(.Trailing, withInset: kLabelHorizontalInsets)
            bodyLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: kLabelVerticalInsets)

            didSetupConstraints = true
        }

        super.updateConstraints()
    }

    func updateFonts() {
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        bodyLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
    }
}