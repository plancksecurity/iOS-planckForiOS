//
//  nonPasteableUiTextField.swift
//  pEp
//
//  Created by Xavier Algarra on 18/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class NonEditMenuUITextField: UITextField {

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
}
