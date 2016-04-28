//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class Constants {
    static let ErrorCodeNotImplemented = 1000

    static func errorNotImplemented(component: String) -> NSError {
        let error = NSError.init(
            domain: component, code: ErrorCodeNotImplemented,
            userInfo: [NSLocalizedDescriptionKey:
                NSLocalizedString("Not implemented",
                    comment: "Error for operation that is not yet implemented")])
        return error
    }
}