//
//  ImageView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Simple view to show a list of images with a constrained width.
 */
class ImageView: UIView {
    var attachedViews = [UIView]() {
        didSet {
            setupConstraints(fixedWidth: frame.size.width)
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

    var fixedWidthConstraint: NSLayoutConstraint?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
    }

    func setupConstraints(fixedWidth: CGFloat) {
        guard attachedViews.count > 0 else {
            return
        }

        if let oldC = fixedWidthConstraint {
            removeConstraint(oldC)
        }

        let newC = NSLayoutConstraint(
            item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width,
            multiplier: 1.0, constant: fixedWidth)
        addConstraint(newC)
        fixedWidthConstraint = newC

        for v in attachedViews {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }

        // distance to the top
        addConstraint(NSLayoutConstraint(
            item: attachedViews[0], attribute: .top, relatedBy: .greaterThanOrEqual,
            toItem: self, attribute: .top, multiplier: 1.0, constant: spacing))

        // distance to the bottom
        addConstraint(NSLayoutConstraint(
            item: attachedViews[attachedViews.count - 1], attribute: .bottom,
            relatedBy: .lessThanOrEqual, toItem: self,
            attribute: .bottom, multiplier: 1.0, constant: -spacing))

        var lastView: UIView?
        for v in attachedViews {
            // aspect ratio for UIImageView
            if let imgView = v as? UIImageView {
                let size = imgView.bounds.size
                let factor = size.height / size.width
                addConstraint(NSLayoutConstraint(
                    item: imgView, attribute: .height, relatedBy: .equal, toItem: imgView,
                    attribute: .width, multiplier: factor, constant: 0.0))
            }
            // center
            addConstraint(NSLayoutConstraint(
                item: v, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX,
                multiplier: 1.0, constant: 0.0))
            // distance left
            addConstraint(NSLayoutConstraint(
                item: v, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: self,
                attribute: .leading, multiplier: 1.0, constant: margin))
            // distance right
            addConstraint(NSLayoutConstraint(
                item: v, attribute: .trailing, relatedBy: .lessThanOrEqual, toItem: self,
                attribute: .trailing, multiplier: 1.0, constant: margin))
            // space between
            if let theLast = lastView {
                addConstraint(NSLayoutConstraint(
                    item: theLast, attribute: .bottom, relatedBy: .lessThanOrEqual,
                    toItem: v, attribute: .top, multiplier: 1.0, constant: -margin))
            }
            lastView = v
        }
    }
}
