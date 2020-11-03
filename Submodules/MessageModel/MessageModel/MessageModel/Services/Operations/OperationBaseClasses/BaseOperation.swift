//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

/**
 Basic NSOperation that can gather errors.
 */
open class BaseOperation: Operation {
    open var comp = "BaseOperation"

    let errorContainer: ErrorContainerProtocol

    static let moduleTitleRegex = try! NSRegularExpression(
        pattern: "<pEpForiOS\\.(\\w+):", options: [])

    public init(parentName: String = #function,
                errorContainer: ErrorContainerProtocol = ErrorPropagator()) {
        self.errorContainer = errorContainer

        super.init()

        comp = "\(type(of: self))"

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
        Log.shared.info("%@: %@", comp, self)
    }
}

// MARK: - ErrorContainerProtocol

extension BaseOperation: ErrorContainerProtocol {

    open var error: Error? {
        return errorContainer.error
    }

    open func addError(_ error: Error) {
        errorContainer.addError(error)
    }

    open var hasErrors: Bool {
        return errorContainer.hasErrors
    }

    public func reset() {
        errorContainer.reset()
    }
}
