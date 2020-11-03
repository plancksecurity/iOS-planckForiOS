//
//  CdServer+NonOptionalConvenienceAccessors.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 08.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/**
 Wrappers over non-optional properties that crash if the property is really nil.
 */
extension CdServer {
    public var credentialsOrCrash: CdServerCredentials {
        guard let theCredentials = credentials else {
            fatalError()
        }
        return theCredentials
    }

    public var addressOrCrash: String {
        guard let theAddress = address else {
            fatalError()
        }
        return theAddress
    }
}
