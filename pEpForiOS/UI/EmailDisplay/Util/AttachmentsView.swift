//
//  AttachmentsView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 Container for a list of views that have some intrinsic content size.
 */
class AttachmentsView: UIView {
    weak var delegate: AttachmentsViewDelegate?

    var attachmentViewContainers = [AttachmentViewContainer]() {
        didSet {
            setupConstraints()
            setUpActions()
        }
    }

    /**
     The space between views.
     */
    var spacing: CGFloat = 10

    /**
     The  minimum distance to the right or left.
     */
    var margin: CGFloat = 10

    var lastConstraints = [NSLayoutConstraint]()

    var gestureRecognizersToAttachments = [UITapGestureRecognizer:AttachmentViewContainer]()

    func setupConstraints() {
        // remove any existing subview
        let subs = subviews
        for sub in subs {
            sub.removeFromSuperview()
        }

        // rm all previously set up constraints
        removeConstraints(lastConstraints)

        guard attachmentViewContainers.count > 0 else {
            return
        }

        for ac in attachmentViewContainers {
            ac.view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(ac.view)
        }

        // distance to the top
        topAnchor.constraint(
            equalTo: attachmentViewContainers[0].view.topAnchor, constant: spacing).isActive = true

        // distance to the bottom
        bottomAnchor.constraint(
            equalTo: attachmentViewContainers[attachmentViewContainers.count - 1].view.bottomAnchor,
            constant: -spacing).isActive = true

        var lastView: UIView?
        for ac in attachmentViewContainers {
            if let imgView = ac.view as? UIImageView {
                // aspect ratio for UIImageView
                let size = imgView.bounds.size
                let factor = size.height / size.width
                imgView.heightAnchor.constraint(
                    equalTo: imgView.widthAnchor, multiplier: factor).isActive = true
            }

            // center
            ac.view.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true

            let guide = readableContentGuide

            // distance left
            ac.view.leadingAnchor.constraint(
                greaterThanOrEqualTo: guide.leadingAnchor).isActive = true

            // distance right
            ac.view.trailingAnchor.constraint(
                lessThanOrEqualTo: guide.trailingAnchor).isActive = true

            // space between
            if let theLast = lastView {
                theLast.bottomAnchor.constraint(
                    equalTo: ac.view.topAnchor, constant: -spacing).isActive = true
            }
            lastView = ac.view
        }

        // store so they can be removed later
        lastConstraints = constraints
    }

    func setUpActions() {
        gestureRecognizersToAttachments.removeAll()
        for ac in attachmentViewContainers {
            setUpAction(attachmentViewContainer: ac)
        }
    }

    func attachmentTapped(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if let ac = gestureRecognizersToAttachments[sender] {
                delegate?.didTap(attachment: ac.attachment, view: sender.view)
            }
        }
    }

    func setUpAction(attachmentViewContainer: AttachmentViewContainer) {
        // remove existing gesture recognizers
        let theSelector = #selector(attachmentTapped(sender:))
        for gr in attachmentViewContainer.view.gestureRecognizers ?? [] {
            gr.removeTarget(self, action: theSelector)
        }

        attachmentViewContainer.view.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: theSelector)
        attachmentViewContainer.view.addGestureRecognizer(tapGesture)
        gestureRecognizersToAttachments[tapGesture] = attachmentViewContainer
    }
}
