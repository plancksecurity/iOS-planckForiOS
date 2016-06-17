//
//  RecipientView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class RecipientView: UIView {
    override var bounds: CGRect {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    var message: Message! {
        didSet {
            update()
        }
    }

    func update() {
        self.translatesAutoresizingMaskIntoConstraints = false
        let views = createLabelContainers()
        var previousView: LabelContainerView? = nil
        for v in views {
            addSubview(v)
            let viewsDict = ["v": v]
            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
                "|[v]|", options: [],
                metrics: nil, views: viewsDict))
            if let previous = previousView {
                addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
                    "V:[prev]-[v]", options: [],
                    metrics: nil, views: ["v": v, "prev": previous]))
            } else {
                addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
                    "V:|[v]", options: [],
                    metrics: nil, views: viewsDict))
            }
            previousView = v
        }
        if let prev = previousView {
            addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
                "V:[prev]|", options: [],
                metrics: nil, views: ["prev": prev]))
        }
    }

    func createLabelContainers() -> [LabelContainerView] {
        for sub in subviews {
            sub.removeFromSuperview()
        }

        var recipientContainers: [LabelContainerView] = []

        if message.to.count > 0 {
            recipientContainers.append(newLabelContainerWithTitle(
                NSLocalizedString("To:", comment: "Title label for showing 'to' recipients"),
                recipients: message.to))
        }

        // TODO: This is only for testing
        if message.to.count > 0 {
            recipientContainers.append(newLabelContainerWithTitle(
                NSLocalizedString("CC:", comment: "Title label for showing 'CC' recipients"),
                recipients: message.to))
        }

        if message.bcc.count > 0 {
            recipientContainers.append(newLabelContainerWithTitle(
                NSLocalizedString("BCC:", comment: "Title label for showing 'BCC' recipients"),
                recipients: message.bcc))
        }

        return recipientContainers
    }

    func newLabelContainerWithTitle(
        title: String, recipients: NSOrderedSet) -> LabelContainerView {
        let container = LabelContainerView.init()

        let titleLabel = UILabel.init()
        titleLabel.text = title
        UIHelper.boldifyLabel(titleLabel)
        updateLabelContainer(container, titleLabel: titleLabel, contacts: recipients)
        return container
    }

    func updateLabelContainer(container: LabelContainerView, titleLabel: UILabel,
                              contacts: NSOrderedSet) {
        var labels: [UILabel] = [titleLabel]
        for contact in contacts {
            if let c = contact as? Contact {
                let label = UILabel.init()
                label.text = c.displayString()
                labels.append(label)
            }
        }
        container.labels = labels
    }

    func subViewsIntrinsicContentSize() -> CGSize {
        var totalSize: CGSize = CGSizeZero
        for v in subviews {
            let size = v.intrinsicContentSize()
            if totalSize.height > 0 {
                totalSize.height = totalSize.height + size.height
            } else {
                totalSize = size
            }
        }
        return totalSize
    }

    override func intrinsicContentSize() -> CGSize {
        //return subViewsIntrinsicContentSize()
        var size = self.bounds.size
        size.height = 100
        return size
    }
}
