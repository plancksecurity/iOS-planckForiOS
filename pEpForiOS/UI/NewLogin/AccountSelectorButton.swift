//
//  AccountSelectorButton.swift
//  pEp
//
//  Created by Martín Brude on 21/2/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

enum AccountType: Int {
    case google
    case microsoft
    case other
}

@IBDesignable
class AccountSelectorButton: UIButton {

    private var type: AccountType = .other

    @IBInspectable var accountType: Int {
        get {
            return type.rawValue
        }
        set(type) {
            self.type = AccountType(rawValue: type) ?? .other
        }
    }

    @IBInspectable
    var normalBackground: UIColor = UIColor.systemBackground {
        didSet {
            backgroundColor = self.normalBackground
        }
    }

    @IBInspectable
    var highlightBackground: UIColor = UIColor.secondarySystemBackground

    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightBackground : normalBackground
        }
    }

    func setBackgroundColor(_ c: UIColor, forState: UIControl.State) -> Void {
        if forState == UIControl.State.normal {
            normalBackground = c
        } else if forState == UIControl.State.highlighted {
            highlightBackground = c
        } else {
            // implement other states as desired
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() -> Void {

        // 1. rounded corners
        layer.cornerRadius = 10.0

        // 2. Default Colors for state
        let backgroundColor = UIColor(hexString: "#FFFBFE")
        setBackgroundColor(backgroundColor, forState: .normal)
        setBackgroundColor(.pEpLightBackground, forState: .highlighted)

        // 3. Add the shadow
        setShadow()

        //4. Text config
        setTextAndImage()
    }

    private func setShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 6.0
        layer.masksToBounds = false
    }

    private func setTextAndImage() {
        var imageName: String
        var text: String
        switch type {
        case .google:
            imageName = "ico-google"
            text = NSLocalizedString("Sign in with Google", comment: "Sign in with Google button title")
        case .microsoft:
            imageName = "ico-windows-group"
            text = NSLocalizedString("Sign in with Microsoft", comment: "Sign in with Microsoft button title")
        case .other:
            imageName = "ico-key"
            text = NSLocalizedString("Sign in with Password", comment: "Sign in with Password button title")
        }
        let image = UIImage(named: imageName)
        setImage(image, for: .normal)
        setTitle(text, for: .normal)
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.numberOfLines = 1
        titleLabel?.setPEPFont(style: .caption1, weight: .regular)
    }
}
