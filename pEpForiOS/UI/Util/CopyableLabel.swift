//
//  CopyableLabel.swift
//  pEp
//
//  Created by Martín Brude on 1/7/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

// Original Source:
// https://stackoverflow.com/questions/1246198/show-iphone-cut-copy-paste-menu-on-uilabel

/// This Subclass of UILabel allows to show the context menu that shows up when the user long press copyable elements like
/// UITextViews and UITextFields
class CopyableLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sharedInit()
    }

    private func sharedInit() {
        isUserInteractionEnabled = true
        let selector = #selector(showMenu)
        let gesture = UILongPressGestureRecognizer(target: self, action: selector)
        addGestureRecognizer(gesture)
    }

    @objc private func showMenu(sender: AnyObject?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared

        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        board.string = text
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
}
