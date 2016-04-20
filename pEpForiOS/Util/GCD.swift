//
//  GCD.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

struct GCD {

    /**
     Since you will do this all the time in UI callbacks.
     */
    static func onMain(block: () -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            block()
        })
    }
}