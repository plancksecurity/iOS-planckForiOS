//
//  TruswordButton.swift
//  pEp
//
//  Created by Martín Brude on 24/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

@IBDesignable
class TrustwordsButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Prevent storyboard error.
        #if TARGET_INTERFACE_BUILDER
        setup()
        #endif
    }

    @IBInspectable var insetPlusHorizontal: CGFloat = 10 {
        didSet {
            updateInset()
        }
    }

    @IBInspectable var insetPlusVertical: CGFloat = 5 {
        didSet {
            updateInset()
        }
    }

    var buttonTitle: String? = "" {
        didSet {
            setTitle(buttonTitle, for: .normal)
        }
    }

    @IBInspectable var textColor: UIColor? = .white {
        didSet {
            setTitleColor(textColor, for: .normal)
        }
    }

    @IBInspectable override var backgroundColor: UIColor? {
        didSet {
            layer.backgroundColor = backgroundColor?.cgColor
        }
    }

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }

    private func setup() {
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center
        isUserInteractionEnabled = false
        clipsToBounds = true
    }

    private func updateInset() {
        var insets = contentEdgeInsets
        insets.left = insets.left + insetPlusHorizontal
        insets.right = insets.right + insetPlusHorizontal
        insets.top = insets.top + insetPlusVertical
        insets.bottom = insets.bottom + insetPlusVertical
        contentEdgeInsets = insets
    }
}
