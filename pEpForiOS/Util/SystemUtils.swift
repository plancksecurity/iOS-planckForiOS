//
//  SystemUtils.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 08/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

//TODO: Duplicate code! Can also be found in MessageModel/SystemUtils. Maybe exctract generic utils to independent "pEpToolBoxIOs" Framework.
/// Calls fatalError() when in debug configuration
public func crash() {
    #if DEBUG
        fatalError()
    #endif
}
