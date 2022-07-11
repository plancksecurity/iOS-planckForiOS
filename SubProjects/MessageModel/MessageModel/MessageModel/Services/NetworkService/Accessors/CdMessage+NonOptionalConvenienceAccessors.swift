//
//  CdMessage+NonOptionalConvenienceAccessors.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 02.04.19.
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
extension CdMessage {
    var parentOrCrash: CdFolder {
        guard let theParent = parent else {
            Log.shared.errorAndCrash(message: "Parent not found")
            return CdFolder.init()
        }
        return theParent
    }
}
