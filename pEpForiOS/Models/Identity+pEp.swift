//
//  Identity+pEp.swift
//  pEp
//
//  Created by Andreas Buff on 08.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Identity {

    public var displayString: String {
        return userName ?? address.trimmed()
    }
}

