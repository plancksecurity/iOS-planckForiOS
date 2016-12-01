//
//  GCD.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

struct GCD {

    /**
     Since you will do this all the time in UI callbacks.
     */
    static func onMain(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: {
            block()
        })
    }
}
