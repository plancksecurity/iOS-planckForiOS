//
//  AnimatedPlaceholderTextfield.swift
//  pEpIOSToolbox
//
//  Created by Alejandro Gelos on 04/10/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import UIKit

@IBDesignable
class AnimatedPlaceholderTextfield: UITextField {
    private var _placeHolder: String?
    private var placeHolderLabelCenterY: NSLayoutConstraint?

    public let placeholderLabel = UILabel()

    @IBInspectable public var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    @IBInspectable public var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    @IBInspectable public var placeholderColor: UIColor = .gray {
        didSet {
            updatePlaceholderLabel()
        }
    }

    override public var placeholder: String? {
        set {

            _placeHolder = newValue
            updatePlaceholderLabel()
        }
        get {
            return ""
        }
    }

    //Add Placeholder Label
    override func awakeFromNib() {
        super.awakeFromNib()

        updatePlaceholderLabel()
        addPlaceholderLabel()
        addKeyboardObservers()
    }

    @objc open func textFieldDidBeginEditing() {
        moveUpPlaceHolderLabel()
    }

    @objc open func textFieldDidEndEditing() {
        guard let text = text, text.isEmpty else { return }
        centerPlaceHolderLabel()
    }
}

// MARK: - Private
extension AnimatedPlaceholderTextfield {
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidEndEditing),
                                               name: UITextField.textDidEndEditingNotification,
                                               object: self)

        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidBeginEditing),
                                               name: UITextField.textDidBeginEditingNotification,
                                               object: self)
    }

    private func addPlaceholderLabel() {
        addSubview(placeholderLabel)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: placeholderLabel, attribute: .width, relatedBy: .equal,
                           toItem: self, attribute: .width, multiplier: 1,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: placeholderLabel, attribute: .centerX, relatedBy: .equal,
                           toItem: self, attribute: .centerX, multiplier: 1,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: placeholderLabel, attribute: .height, relatedBy: .equal,
                           toItem: self, attribute: .height, multiplier: 1,
                           constant: 0).isActive = true
        placeHolderLabelCenterY = NSLayoutConstraint(item: placeholderLabel, attribute: .centerY,
                                                     relatedBy: .equal, toItem: self,
                                                     attribute: .centerY, multiplier: 1, constant: 0)
        placeHolderLabelCenterY?.isActive = true
    }

    /// Update placeholder label values with original placeholder values
    private func updatePlaceholderLabel() {
        placeholderLabel.text = _placeHolder
        placeholderLabel.font = font
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.textAlignment = textAlignment
    }

    /// Do animation to move placeHolder label above textfield
    private func moveUpPlaceHolderLabel() {
        placeHolderLabelCenterY?.constant = -placeholderLabel.frame.height / 2 - 10
        doViewAnimation()
    }

    /// Do animations to move placeholder label back to textfield placeholder origin
    private func centerPlaceHolderLabel() {
        placeHolderLabelCenterY?.constant = 0
        doViewAnimation()
    }

    private func doViewAnimation() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.layoutIfNeeded()
        }
    }
}
