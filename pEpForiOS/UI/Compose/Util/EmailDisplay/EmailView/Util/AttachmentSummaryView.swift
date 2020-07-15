//
//  AttachmentSummaryView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

class AttachmentSummaryView: UIView {
    /**
     Gives information about the attachment, without introducing a dependency.
     */
    struct AttachmentInfo {
        let filename: String
        let theExtension: String?
    }

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

    let attachmentInfo: AttachmentInfo
    let iconImage: UIImage?

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

    init(attachmentInfo: AttachmentInfo, iconImage: UIImage?) {
        self.attachmentInfo = attachmentInfo
        self.iconImage = iconImage
        super.init(frame: CGRect.zero)

        layer.borderColor = UIColor.pEpGreen.cgColor
        layer.borderWidth = 1.5
        layer.cornerRadius = 30
        layer.masksToBounds = true
    }

    override func didMoveToSuperview() {
        if superview != nil {
            setupViewsAndInternalConstraints()
        }
    }

    func setupViewsAndInternalConstraints() {
        translatesAutoresizingMaskIntoConstraints = false

        let subs = subviews
        for v in subs {
            v.removeFromSuperview()
        }

        let (labelFilename, labelExtension) = createLabels()
        addSubview(labelFilename)

        let guide = self
        labelFilename.centerXAnchor.constraint(equalTo: guide.centerXAnchor).isActive = true
        labelFilename.topAnchor.constraint(equalTo: guide.topAnchor, constant: spaceVertical).isActive = true

        labelFilename.widthAnchor.constraint(
            lessThanOrEqualTo: guide.widthAnchor, multiplier: 1,
            constant: 2 * -marginHorizontal).isActive = true

        var lastVerticalView: UIView = labelFilename

        if let icon = iconImage {
            let imgView = UIImageView(image: icon)
            imgView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imgView)

            imgView.topAnchor.constraint(
                equalTo: lastVerticalView.bottomAnchor, constant: spaceVertical).isActive = true
            imgView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            imgView.widthAnchor.constraint(
                lessThanOrEqualTo: guide.widthAnchor, multiplier: 1,
                constant: 2 * -marginHorizontal).isActive = true
            lastVerticalView = imgView
        }

        if let labelExt = labelExtension {
            addSubview(labelExt)
            labelExt.centerXAnchor.constraint(equalTo: guide.centerXAnchor).isActive = true

            labelExt.topAnchor.constraint(
                equalTo: lastVerticalView.bottomAnchor, constant: spaceVertical).isActive = true

            labelExt.widthAnchor.constraint(
                lessThanOrEqualTo: guide.widthAnchor, multiplier: 1,
                constant: 2 * -marginHorizontal).isActive = true

            lastVerticalView = labelExt
        }
        lastVerticalView.bottomAnchor.constraint(
            equalTo: guide.bottomAnchor, constant: -marginVertical).isActive = true
    }

    func createLabels() -> (UILabel, UILabel?) {
        let nameLabel = createLabel()
        nameLabel.numberOfLines = 0
        nameLabel.text = attachmentInfo.filename

        if let theExt = attachmentInfo.theExtension {
            let extLabel = createLabel()
            extLabel.numberOfLines = 1
            extLabel.text = theExt.uppercased()
            return (nameLabel, extLabel)
        }

        return (nameLabel, nil)
    }

    func createLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        label.allowsDefaultTighteningForTruncation = true
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        return label
    }
}
