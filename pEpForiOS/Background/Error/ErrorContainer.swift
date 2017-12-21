//
//  ErrorContainer.swift
//  pEp
//
//  Created by Andreas Buff on 20.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

open class ErrorContainer: ServiceErrorProtocol {
    public var error: Error?

    public init() {}

    public func addError(_ error: Error) {
        if self.error == nil {
            self.error = error
        }
    }

    public func hasErrors() -> Bool {
        return error != nil
    }
}

