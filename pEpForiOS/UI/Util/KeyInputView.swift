//
//  KeyInputView.swift
//  pEp
//
//  Created by Alejandro Gelos on 15/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class KeyInputView: UIView {
    var _inputView: UIView?

    override var canBecomeFirstResponder: Bool { return true }
    override var canResignFirstResponder: Bool { return true }

    override var inputView: UIView? {
        set { _inputView = newValue }
        get { return _inputView }
    }
}

// MARK: - UIKeyInput

//Modify if need more functionality
extension KeyInputView: UIKeyInput {
    var hasText: Bool { return false }
    func insertText(_ text: String) {}
    func deleteBackward() {}
}
