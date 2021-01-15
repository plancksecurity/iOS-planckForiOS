//
//  CdAccount+NonOptionalConvenienceAccessors.swift.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 25.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// Wrappers over non-optional properties that crash if the property is really nil.
extension CdAccount {
    var identityOrCrash: CdIdentity {
        guard let theIdentity = identity else {
            fatalError()
        }
        return theIdentity
    }
}
