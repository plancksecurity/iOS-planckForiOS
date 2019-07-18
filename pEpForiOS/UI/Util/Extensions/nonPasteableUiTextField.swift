//
//  nonPasteableUiTextField.swift
//  pEp
//
//  Created by Xavier Algarra on 18/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

class nonPasteableUiTextField: UITextField {

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

    if action == #selector(copy(_:)) || action == #selector(selectAll(_:)) || action == #selector(paste(_:)) {

    return false
    }

    return super.canPerformAction(action, withSender: sender)
    }
}
