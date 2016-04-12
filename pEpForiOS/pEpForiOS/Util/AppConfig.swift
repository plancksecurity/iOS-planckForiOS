//
//  AppConfig.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import Foundation

/**
 Some cross cutting concerns, like core data access, networking, etc.
 This object might be implemented as a singleton, which means that all the
 contained objects don't have to be one.
 */
class AppConfig: NSObject {

    var coreDataUtil: CoreDataUtil!

}
