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
open class BaseOperation: Operation, ServiceErrorProtocol {
    open var comp = "BaseOperation"

    /**
     Don't even start if an error already has occurred, e.g. through another Operation.
     */
    var bailOutEarlyOnError = true

    let errorContainer: ServiceErrorProtocol

    open var error: NSError? {
        return errorContainer.error
    }

    open func addError(_ error: NSError) {
        errorContainer.addError(error)
    }

    open func hasErrors() -> Bool {
        return errorContainer.hasErrors()
    }

    public init(parentName: String? = nil, errorContainer: ServiceErrorProtocol = ErrorContainer()) {
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
        Log.info(component: comp, content: "init()")
    }

    deinit {
        Log.info(component: comp, content: "deinit()")
    }

    public func shouldRun() -> Bool {
        if isCancelled || (bailOutEarlyOnError && hasErrors()) {
            return false
        }
        return true
    }
}
