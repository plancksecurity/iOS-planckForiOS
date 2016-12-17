//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

/**
 Basic NSOperation that can gather errors.
 */
open class BaseOperation: Operation, ErrorProtocol {
    open var comp = "BaseOperation"
    let errorContainer: ErrorProtocol

    open var error: NSError? {
        return errorContainer.error
    }

    open func addError(_ error: NSError) {
        errorContainer.addError(error)
    }

    open func hasErrors() -> Bool {
        return errorContainer.hasErrors()
    }

    public init(parentName: String? = nil, errorContainer: ErrorProtocol = ErrorContainer()) {
        self.errorContainer = errorContainer

        super.init()

        comp = String(describing: self)

        do {
            let regex = try NSRegularExpression(pattern: "<pEpForiOS\\.(\\w+):", options: [])
            if let m = regex.firstMatch(in: comp, options: [], range: comp.wholeRange()) {
                if m.numberOfRanges > 1 {
                    let r = m.rangeAt(1)
                    let s = comp as NSString
                    comp = s.substring(with: r)
                }
            }
        } catch let error as NSError {
            Log.error(component: comp, error: error)
        }

        if let n = parentName {
            comp = "\(comp): \(n)"
        }
        self.name = comp
    }

    public func shouldRun() -> Bool {
        if isCancelled {
            return false
        }
        if hasErrors() {
            return false
        }
        return true
    }
}
