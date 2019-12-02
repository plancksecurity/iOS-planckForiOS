//
//  AnimatedPlaceholderTextfield.swift
//  pEpIOSToolbox
//
//  Created by Alejandro Gelos on 04/10/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import UIKit

@IBDesignable
/// TextField with animated placeholder (moves above TextField), background color and text color.
/// If textField text is empty placeholde will be center in TextField (as normal). Else placeHolder will move above the TextField
/// Its also possible to configure different text and blackground colors, when TextField text is empty or not.
class AnimatedPlaceholderTextfield: UITextField {
    private var _placeHolder: String?
    private var originalTextColor: UIColor?
    private var originalBackgroundColor: UIColor?
    private var placeHolderLabelCenterY: NSLayoutConstraint?

    private let placeholderLabel = UILabel()

    @IBInspectable
    /// Use this property to set TextField border color
    var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    @IBInspectable
    /// Use this property to set TextField border width
    var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    @IBInspectable
    var placeholderColor: UIColor = .gray {
        didSet {
            updatePlaceholderLabel()
        }
    }

    @IBInspectable
    override var placeholder: String? {
        set {
            _placeHolder = newValue
            updatePlaceholderLabel()
        }
        get {
            return ""
        }
    }

    override var text: String? {
        didSet {
            updateTextFieldTextColor()
            updateTextFieldBackgroundColor()
            if text?.isEmpty == false {
                DispatchQueue.main.async { [weak self] in
                    guard let me = self else {
                        Log.shared.lostMySelf()
                        return
                    }
                    me.moveUpPlaceHolderLabel()
                }
            }
        }
    }

    @IBInspectable
    /// Use this property to set TextField background color when text is not empty
    var backgroundColorWithText: UIColor? = nil {
        didSet {
            updateTextFieldBackgroundColor()
        }
    }

    @IBInspectable
    /// Use this property to set TextField text color when text is not empty
    var textColorWithText: UIColor? = nil {
        didSet {
            updateTextFieldTextColor()
        }
    }

    //Add Placeholder Label
    override func awakeFromNib() {
        super.awakeFromNib()

        originalTextColor = textColor
        originalBackgroundColor = backgroundColor

        updatePlaceholderLabel()
        addPlaceholderLabel()
        addKeyboardObservers()
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

        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChangeCharacters),
                                               name: UITextField.textDidChangeNotification,
                                               object: self)
    }

    @objc private func textFieldDidBeginEditing() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.moveUpPlaceHolderLabel()
        }
    }

    @objc private func textFieldDidEndEditing() {
        guard let text = text, text.isEmpty else {
            //dont not center if text is not empty
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.centerPlaceHolderLabel()
        }
    }

    @objc private func textFieldDidChangeCharacters() {
        updateTextFieldTextColor()
        updateTextFieldBackgroundColor()
    }

    private func updateTextFieldBackgroundColor() {
        guard let newBackgroundColor = backgroundColorWithText,
            let text = text else {
                //if not set, then do nothing
                return
        }
        backgroundColor = text.isEmpty ? originalBackgroundColor : newBackgroundColor
    }

    private func updateTextFieldTextColor() {
        guard let newTextColor = textColorWithText,
            let text = text else {
            //if not set, then do nothing
            return
        }
        textColor = text.isEmpty ? originalTextColor : newTextColor
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
            self?.superview?.layoutIfNeeded()
        }
    }
}
