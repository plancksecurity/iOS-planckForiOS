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
open class BaseOperation: Operation {
    open var comp = "BaseOperation"
    open var errors: [NSError] = []

    open var error: NSError? {
        return errors.first
    }

    open func addError(_ error: NSError) {
        errors.append(error)
    }

    open func hasErrors() -> Bool {
        return !errors.isEmpty
    }

    public init(name: String? = nil) {
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

        if let n = name {
            comp = "\(comp): \(n)"
            self.name = comp
        }
    }
}
