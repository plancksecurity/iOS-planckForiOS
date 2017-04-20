//
//  UIButton+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIButton {
    /**
     Makes the button the typical look for a pEp button used in the handshake dialogs.
     */
    func pEpIfyForTrust(backgroundColor: UIColor, textColor: UIColor) {
        layer.cornerRadius = 2
        self.backgroundColor = backgroundColor
        setTitleColor(textColor, for: .normal)
    }
}
