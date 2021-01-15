//
//  CdMessage+NonOptionalConvenienceAccessors.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 02.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/**
 Wrappers over non-optional properties that crash if the property is really nil.
 */
extension CdMessage {
    var parentOrCrash: CdFolder {
        guard let theParent = parent else {
            fatalError()
        }
        return theParent
    }
}
