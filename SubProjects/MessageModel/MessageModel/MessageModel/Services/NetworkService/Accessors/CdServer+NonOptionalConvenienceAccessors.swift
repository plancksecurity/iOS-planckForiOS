//
//  CdServer+NonOptionalConvenienceAccessors.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 08.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

/**
 Wrappers over non-optional properties that crash if the property is really nil.
 */
extension CdServer {
    var credentialsOrCrash: CdServerCredentials {
        guard let theCredentials = credentials else {
            fatalError()
        }
        return theCredentials
    }

    var addressOrCrash: String {
        guard let theAddress = address else {
            Log.shared.errorAndCrash(message: "Address not found")
            return ""
        }
        return theAddress
    }
}
