//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import pEpUtilities

/**
 Basic NSOperation that can gather errors.
 */
open class BaseOperation: Operation, ServiceErrorProtocol {
    open var comp = "BaseOperation"

    let errorContainer: ServiceErrorProtocol

    static let moduleTitleRegex = try! NSRegularExpression(
        pattern: "<pEpForiOS\\.(\\w+):", options: [])

    open var error: Error? {
        return errorContainer.error
    }

    open func addError(_ error: Error) {
        errorContainer.addError(error)
    }

    open func hasErrors() -> Bool {
        return errorContainer.hasErrors()
    }

    public init(parentName: String = #function,
                errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        self.errorContainer = errorContainer

        super.init()

        comp = String(describing: self)

        if let m = BaseOperation.moduleTitleRegex.firstMatch(
            in: comp, options: [], range: comp.wholeRange()) {
            if m.numberOfRanges > 1 {
                let r = m.range(at: 1)
                let s = comp as NSString
                comp = s.substring(with: r)
            }
        }

        comp = "\(comp) \(unsafeBitCast(self, to: UnsafeRawPointer.self)) [\(parentName)]"
        self.name = comp
    }

    func logSelf(functionName: String) {
        Logger.backendLogger.log("%{public}@: %{public}@", comp, self)
    }
}
