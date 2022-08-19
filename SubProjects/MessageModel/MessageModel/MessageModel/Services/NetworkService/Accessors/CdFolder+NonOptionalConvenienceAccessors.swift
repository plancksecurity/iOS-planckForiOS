//
//  CdFolder+NonOptionalConvenienceAccessors.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 22.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/**
 Wrappers over non-optional properties that crash if the property is really nil.
 */
extension CdFolder {
    var nameOrCrash: String {
        guard let theName = name else {
            Log.shared.errorAndCrash(message: "CdFolder Name not found")
            return ""
        }
        return theName
    }

    var accountOrCrash: CdAccount {
        guard let theAccount = account else {
            Log.shared.errorAndCrash(message: "CdAccount Name not found")
            return CdAccount()
        }
        return theAccount
    }
}
