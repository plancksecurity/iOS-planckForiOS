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

    let errorContainer: ServiceErrorProtocol

    open var error: Error? {
        return errorContainer.error
    }

    open func addError(_ error: Error) {
        errorContainer.addError(error)
    }

    open func hasErrors() -> Bool {
        return errorContainer.hasErrors()
    }

    public init(parentName: String? = nil,
                errorContainer: ServiceErrorProtocol = ErrorContainer()) {
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

        if let pn = parentName {
            comp = "\(comp) [\(pn)]"
        }
        self.name = comp
        Log.info(component: comp, content: "\(#function)")
    }

    deinit {
        Log.info(component: comp, content: "\(#function)")
    }

    public func shouldRun() -> Bool {
        if isCancelled || hasErrors() {
            return false
        }
        return true
    }

    func logSelf(functionName: String) {
        Log.log(comp: comp, mySelf: self, functionName: functionName)
    }
}
