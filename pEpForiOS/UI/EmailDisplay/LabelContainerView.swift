//
//  LabelContainerView.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public protocol LabelContainerViewDelegate: class {
}

/**
 A view that displays a bunch of contacts in a way that the layout flow resembles that of a
 UITextView, only the components are UILabel, can be colored and a delegate can be called
 when they are tapped.
 Useful for displaying Contacts.
 */
public class LabelContainerView: UIView {
    public weak var delegate: LabelContainerViewDelegate? = nil

    let paddingX: CGFloat = 5.0
    let paddingY: CGFloat = 5.0

    var labels: [UILabel] = [] {
        didSet {
            refresh()
        }
    }
    var frames: [UILabel:CGRect] = [:]

    var lastKnownWidth: CGFloat = 0.0
    var lastLabel: UILabel? = nil

    public func refresh() {
        for sub in subviews {
            sub.removeFromSuperview()
        }

        var labelNum = 0
        for label in labels {
            addSubview(label)
            labelNum = labelNum + 1
        }
        setNeedsLayout()
    }

    func calculateFrames() {
        frames.removeAll()

        let width = self.bounds.width
        var pos = CGPoint(x: paddingX, y: paddingY)
        for sub in subviews {
            if let label = sub as? UILabel {
                let labelSize = label.intrinsicContentSize()
                // If not at the left, and the width exceeds the horizontal space, wrap
                if pos.x > paddingX && labelSize.width + pos.x >= width {
                    pos = lineWrap(pos, paddingX: paddingX, incY: paddingY + labelSize.height)
                }
                let frame = CGRect.init(origin: pos, size: labelSize)
                frames[label] = frame
                pos.x = pos.x + paddingX + labelSize.width
            }
        }
    }

    override public func layoutSubviews() {
        calculateFrames()
        for sub in subviews {
            if let label = sub as? UILabel {
                if let frame = frames[label] {
                    label.frame = frame
                }
                lastLabel = label
            }
        }
        if self.bounds.width != lastKnownWidth {
            invalidateIntrinsicContentSize()
        }
    }

    override public func intrinsicContentSize() -> CGSize {
        lastKnownWidth = self.bounds.width
        if let l = lastLabel {
            return CGSize.init(width: lastKnownWidth,
                               height: l.frame.origin.y + l.frame.size.height + paddingY)
        }
        let l = UILabel.init()
        l.text = "Test"
        return CGSize.init(width: lastKnownWidth,
                           height: l.bounds.size.height + paddingX + paddingY)
    }

    func lineWrap(pos: CGPoint, paddingX: CGFloat, incY: CGFloat) -> CGPoint {
        var pos2 = pos
        pos2.x = paddingX
        pos2.y = pos.y + incY
        return pos2
    }
}