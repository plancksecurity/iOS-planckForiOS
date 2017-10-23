//
//  UILabel+Extension.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 16/05/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func convertToLoginErrorLabel(placeHolder: String) {
        self.backgroundColor = UIColor.clear
        self.tintColor = UIColor.white
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.0
        self.textColor = UIColor.red
    }
}

class CopyLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    func sharedInit() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(
            target: self, action:#selector(showMenu)))
    }

    @objc func showMenu(sender: AnyObject?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        board.string = text
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }

}
