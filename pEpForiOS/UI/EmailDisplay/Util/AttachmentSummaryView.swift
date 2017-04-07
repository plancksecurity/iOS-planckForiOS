//
//  AttachmentSummaryView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class AttachmentSummaryView: UIView {
    /**
     The gap between labels.
     */
    let spaceVertical: CGFloat = 8

    /**
     Amount of margin at the top, and the bottom.
     */
    let marginVertical: CGFloat = 8

    /**
     Amount of margin left and right.
     */
    let marginHorizontal: CGFloat = 8

    let attachment: Attachment

    /**
     The view on top that one.
     */
    var upperView: UIView?

    /**
     The view below that one.
     */
    var lowerView: UIView?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(attachment: Attachment) {
        self.attachment = attachment
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.pEpGreen
        setupViewsAndInternalConstraints()
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }

    func setupViewsAndInternalConstraints() {
        translatesAutoresizingMaskIntoConstraints = false

        let subs = subviews
        for v in subs {
            v.removeFromSuperview()
        }

        let (labelFilename, labelExtension) = createLabels()
        addSubview(labelFilename)

        let guide = readableContentGuide
        labelFilename.centerXAnchor.constraint(equalTo: guide.centerXAnchor).isActive = true
        labelFilename.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        labelFilename.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor,
                                               constant: marginHorizontal)
        labelFilename.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor,
                                                constant: -marginHorizontal)

        if let labelExt = labelExtension {
            addSubview(labelExt)
            labelExt.centerXAnchor.constraint(equalTo: guide.centerXAnchor).isActive = true

            labelExt.topAnchor.constraint(
                equalTo: labelFilename.bottomAnchor, constant: spaceVertical).isActive = true

            labelExt.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor,
                                              constant: marginHorizontal)
            labelExt.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor,
                                               constant: -marginHorizontal)

            labelExt.bottomAnchor.constraint(
                equalTo: guide.bottomAnchor, constant: -marginVertical).isActive = true
        } else {
            labelFilename.bottomAnchor.constraint(
                equalTo: guide.bottomAnchor, constant: -marginVertical).isActive = true
        }
    }

    func createLabels() -> (UILabel, UILabel?) {
        let (name, ext) = attachment.fileName.splitFileExtension()

        let nameLabel = createLabel()
        nameLabel.numberOfLines = 0
        nameLabel.text = name

        if let theExt = ext {
            let extLabel = createLabel()
            extLabel.numberOfLines = 1
            extLabel.text = theExt.uppercased()
            return (nameLabel, extLabel)
        }

        return (nameLabel, nil)
    }

    func createLabel() -> UILabel {
        let label = UILabel(forAutoLayout: ())
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        label.allowsDefaultTighteningForTruncation = true
        label.lineBreakMode = .byCharWrapping
        return label
    }
}
