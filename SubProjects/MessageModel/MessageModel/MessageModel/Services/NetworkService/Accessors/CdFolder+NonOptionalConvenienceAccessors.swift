//
//  CdFolder+NonOptionalConvenienceAccessors.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 22.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

/**
 Wrappers over non-optional properties that crash if the property is really nil.
 */
extension CdFolder {
    var nameOrCrash: String {
        guard let theName = name else {
            fatalError()
        }
        return theName
    }

    var accountOrCrash: CdAccount {
        guard let theAccount = account else {
            fatalError()
        }
        return theAccount
    }
}
