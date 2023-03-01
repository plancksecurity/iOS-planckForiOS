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
    case google = 0
    case microsoft = 1
    case other = 2
}

/// How to use this button:
///
/// 1. Create a button in IB.
/// 2. Set the right height, probably 56 pt, and constraints (not fixed width).
/// 3. Set the `accountType` value in IB.
@IBDesignable
class AccountSelectorButton: UIButton {

    private var type: AccountType = .other

    /// To change the button type set the value of the this property on IB.
    /// Use only the numbers of the AccountType enum.
    /// The default value of this computed variable will be ignored.
    @IBInspectable
    var accountType: Int = 2 {
        didSet {
            self.type = AccountType(rawValue: accountType) ?? .other
            commonInit()
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
#if !TARGET_INTERFACE_BUILDER
        commonInit()
#endif
    }

}

extension AccountSelectorButton {

    private func setBackgroundColor(_ color: UIColor, forState: UIControl.State) -> Void {
        if forState == UIControl.State.normal {
            normalBackground = color
        } else if forState == UIControl.State.highlighted {
            highlightBackground = color
        } else {
            // implement other states as desired
        }
    }

    private func commonInit() -> Void {
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

        switch AccountType(rawValue: accountType) {
        case .google:
            imageName = "ico-google"
            text = NSLocalizedString("Sign in with Google", comment: "Sign in with Google button title")
        case .microsoft:
            imageName = "ico-windows-group"
            text = NSLocalizedString("Sign in with Microsoft", comment: "Sign in with Microsoft button title")
        case .other:
            imageName = "ico-key"
            text = NSLocalizedString("Sign in with Password", comment: "Sign in with Password button title")
        case .none:
            Log.shared.errorAndCrash("Not found")
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
