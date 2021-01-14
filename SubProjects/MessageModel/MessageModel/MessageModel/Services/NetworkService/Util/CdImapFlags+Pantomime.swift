//
//  CdImapFlags+Pantomime.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import PantomimeFramework

extension CdImapFlags {
    open func update(cwFlags: CWFlags) {
        update(rawValue16: cwFlags.rawFlagsAsShort())
    }

    open func pantomimeFlags() -> CWFlags? {
        let n = Int(rawFlagsAsShort())
        let cwFlags = CWFlags(int: n)
        return cwFlags
    }
}
