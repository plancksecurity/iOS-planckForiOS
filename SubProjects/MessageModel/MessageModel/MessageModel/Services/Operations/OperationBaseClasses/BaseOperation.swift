//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/**
 Basic NSOperation that can gather errors.
 */
class BaseOperation: Operation {
    var comp = "BaseOperation"

    let errorContainer: ErrorContainerProtocol

    static let moduleTitleRegex = try! NSRegularExpression(
        pattern: "<pEpForiOS\\.(\\w+):", options: [])

    init(parentName: String = #function,
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
}

// MARK: - ErrorContainerProtocol

extension BaseOperation: ErrorContainerProtocol {

    var error: Error? {
        return errorContainer.error
    }

    func addError(_ error: Error) {
        errorContainer.addError(error)
    }

    var hasErrors: Bool {
        return errorContainer.hasErrors
    }

    func reset() {
        errorContainer.reset()
    }
}
