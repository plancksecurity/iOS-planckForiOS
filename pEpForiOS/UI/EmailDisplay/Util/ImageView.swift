//
//  ImageView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Container for a list of views that have some intrinsic content size.
 */
class ImageView: UIView {
    var attachedViews = [UIView]() {
        didSet {
            setupConstraints()
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

    func setupConstraints() {
        // remove any existing subview
        let subs = subviews
        for sub in subs {
            sub.removeFromSuperview()
        }

        // rm all previously set up constraints
        removeConstraints(lastConstraints)

        guard attachedViews.count > 0 else {
            return
        }

        for v in attachedViews {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }

        // distance to the top
        topAnchor.constraint(
            equalTo: attachedViews[0].topAnchor, constant: spacing).isActive = true

        // distance to the bottom
        bottomAnchor.constraint(
            equalTo: attachedViews[attachedViews.count - 1].bottomAnchor,
            constant: -spacing).isActive = true

        var lastView: UIView?
        for v in attachedViews {
            // aspect ratio for UIImageView
            if let imgView = v as? UIImageView {
                let size = imgView.bounds.size
                let factor = size.height / size.width
                imgView.heightAnchor.constraint(
                    equalTo: imgView.widthAnchor, multiplier: factor).isActive = true

                // distance left
                v.leftAnchor.constraint(
                    greaterThanOrEqualTo: self.leftAnchor, constant: margin).isActive = true

                // distance right
                v.rightAnchor.constraint(
                    lessThanOrEqualTo: self.rightAnchor, constant: -margin).isActive = true
            } else {
                print("general attachment: \(v)")

                let guide = readableContentGuide

                // distance left
                v.leadingAnchor.constraint(
                    greaterThanOrEqualTo: guide.leadingAnchor).isActive = true

                // distance right
                v.trailingAnchor.constraint(
                    lessThanOrEqualTo: guide.trailingAnchor).isActive = true
            }
            // center
            v.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true

            // space between
            if let theLast = lastView {
                theLast.bottomAnchor.constraint(
                    equalTo: v.topAnchor, constant: -spacing).isActive = true
            }
            lastView = v
        }

        // store so they can be removed later
        lastConstraints = constraints
    }
}
