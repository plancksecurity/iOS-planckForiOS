//
//  Identity+pEp.swift
//  pEp
//
//  Created by Andreas Buff on 08.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

extension Identity {

    public var displayString: String {
        return userName ?? address.trimmed()
    }

    public func decorateButton(button: UIButton) {
        button.setTitleColor(.black, for: .normal)
        if let color = PEPUtils.pEpColor(identity: self).uiColor() {
            button.backgroundColor = color
        } else {
            let buttonDefault = UIButton()
            button.backgroundColor = buttonDefault.backgroundColor
            button.tintColor = buttonDefault.tintColor
        }
    }
}

