//
//  CdServerCredentials+NonOptionalConvenienceAccessors.swift.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 08.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/**
 Wrappers over non-optional properties that crash if the property is really nil.
 */
extension CdServerCredentials {
    public var loginNameOrCrash: String {
        guard let theLoginName = loginName else {
            fatalError()
        }
        return theLoginName
    }
}
