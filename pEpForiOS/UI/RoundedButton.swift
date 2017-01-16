//
//  RoundedButton.swift
//  Button Test App
//
//  Created by Igor Vojinovic on 12/28/16.
//  Copyright © 2016 Igor Vojinovic. All rights reserved.
//

import UIKit

@IBDesignable class RoundedButton: UIButton {
    
    @IBInspectable var borderColor: UIColor?
    @IBInspectable var borderHighlightedColor: UIColor?
    @IBInspectable var backgroundHighlightedColor: UIColor?
    
    private var initialBackgroundColor: UIColor! = nil
    
    override func awakeFromNib() {
        initialBackgroundColor = backgroundColor
    }

    override func draw(_ rect: CGRect) {
        layer.cornerRadius = 20.0
        
        guard let border = borderColor else { return }
        layer.borderWidth = 2.0
        layer.borderColor = isHighlighted ? borderHighlightedColor?.cgColor : border.cgColor
        layer.masksToBounds = true
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                if let bg = backgroundHighlightedColor {
                    backgroundColor = bg
                }
                setTitleColor(initialBackgroundColor, for: .highlighted)
            } else {
                backgroundColor = initialBackgroundColor
            }
        }
    }
}
