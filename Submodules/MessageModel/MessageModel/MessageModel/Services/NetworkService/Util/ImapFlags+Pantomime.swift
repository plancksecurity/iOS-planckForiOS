//
//  ImapFlags+Pantomime.swift
//  pEp
//
//  Created by Andreas Buff on 10.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import PantomimeFramework

extension ImapFlags {
    open func pantomimeFlags() -> CWFlags? {
        let n = Int(rawFlagsAsShort())
        let cwFlags = CWFlags(int: n)
        return cwFlags
    }
}
