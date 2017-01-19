//
//  ServiceErrorProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 For exchanging errors between `BaseOperation`s.
 */
public protocol ServiceErrorProtocol {
    var error: NSError? { get }
    func addError(_ error: NSError)
    func hasErrors() -> Bool
}

open class ErrorContainer: ServiceErrorProtocol {
    public var error: NSError?

    public init() {}

    public func addError(_ error: NSError) {
        if self.error == nil {
            self.error = error
        }
    }

    public func hasErrors() -> Bool {
        return error != nil
    }
}
