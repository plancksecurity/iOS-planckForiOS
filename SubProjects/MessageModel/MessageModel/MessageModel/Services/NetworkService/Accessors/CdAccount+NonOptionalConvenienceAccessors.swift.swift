//
//  CdAccount+NonOptionalConvenienceAccessors.swift.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 25.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/// Wrappers over non-optional properties that crash if the property is really nil.
extension CdAccount {
    var identityOrCrash: CdIdentity {
        guard let theIdentity = identity else {
            Log.shared.errorAndCrash(message: "Identity not found")
            return CdIdentity.init()
        }
        return theIdentity
    }
}
