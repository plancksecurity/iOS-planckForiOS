//
//  EmailTextField.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class EmailTextField: UITextField {
    override func caretRectForPosition(position: UITextPosition) -> CGRect {
        return super.caretRectForPosition(self.endOfDocument)
    }
}