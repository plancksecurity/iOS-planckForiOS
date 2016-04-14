//
//  AppConfig.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Some cross cutting concerns, like core data access, networking, etc.
 This object might be implemented as a singleton, which means that all the
 contained objects don't have to be one.
 */
class AppConfig: NSObject {

    let coreDataUtil: CoreDataUtil = CoreDataUtil()
    let connectionManager: ConnectionManager

    override init() {
        connectionManager = ConnectionManager(coreDataUtil: coreDataUtil)
    }

}
