//
//  AnimatedPlaceholderTextfield.swift
//  pEpIOSToolbox
//
//  Created by Alejandro Gelos on 04/10/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import UIKit

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

@IBDesignable
/// TextField with animated placeholder (moves above TextField).
/// If textField text is empty and not first responder placeholde will be center in TextField (as normal).
/// Else placeHolder will move above the TextField.
/// To set textField text and move placeholder up without animation use set(text: _, animated: _)
/// Its also possible to configure different text and blackground colors, when TextField text is empty or not.
class AnimatedPlaceholderTextfield: UITextField {
    private var _placeHolder: String?
    private var isAnimationEnable: Bool = true
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

    /// Set textField text and move placeholder up animated
    /// To set text and move placeholder up without animation use set(text: _, animated: _)
    override var text: String? {
        didSet {
            updateTextFieldTextColor()
            updateTextFieldBackgroundColor()
            if text?.isEmpty == false {
                //Text can be set direcly from this property or with a func to enable or disable
                // placeholder animation.
                //Keep current isAnimationEnable value in animated, to pass it to the block.
                //Set isAnimationEnable to default value (true). So next time text is modify
                // from this property directly, it will be animated.
                let animated = isAnimationEnable
                isAnimationEnable = true
                DispatchQueue.main.async { [weak self] in
                    guard let me = self else {
                        Log.shared.lostMySelf()
                        return
                    }
                    me.moveUpPlaceHolderLabel(animated: animated)
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

    /// Use this function to set textField text with placeholder animation enalbe or disable.
    /// If disable, texField placeholder will move up at once.
    /// - Parameters:
    ///   - text: text to set to the textField text
    ///   - animated: enable or disable the textField placeholder going up animation.
    func set(text: String?, animated: Bool = true) {
        isAnimationEnable = animated
        DispatchQueue.main.async {
            self.text = text
        }
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
    private func moveUpPlaceHolderLabel(animated: Bool = true) {
        placeHolderLabelCenterY?.constant = -placeholderLabel.frame.height / 2 - 10
        if animated {
            doViewAnimation()
        }
    }

    /// Do animations to move placeholder label back to textfield placeholder origin
    private func centerPlaceHolderLabel(animated: Bool = true) {
        placeHolderLabelCenterY?.constant = 0
        if animated {
            doViewAnimation()
        }
    }

    private func doViewAnimation() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.superview?.layoutIfNeeded()
        }
    }
}
