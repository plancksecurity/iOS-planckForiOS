//
//  ObservableValue.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class ObservableValue<T> {
    var value: T? {
        didSet {
            reapAndInvokeObservers()
        }
    }

    init(value: T?) {
        self.value = value
    }

    public func observe(fn: @escaping ObservableFunc<T>) {
        let wr = ObservableFuncWrapper(fn: fn)
        observers.append(Weak(value: wr))
    }

    private func reapAndInvokeObservers() {
        var newObservers = [Weak<ObservableFuncWrapper<T>>]()
        for ob in observers {
            if let wr = ob.value {
                newObservers.append(ob)
                wr.fn(value)
            }
        }
        observers = newObservers
    }

    private var observers = [Weak<ObservableFuncWrapper<T>>]()
}

typealias ObservableFunc<T> = (_ newValue: T?) -> Void

class ObservableFuncWrapper<T>: AnyObject {
    let fn: ObservableFunc<T>

    init(fn: @escaping ObservableFunc<T>) {
        self.fn = fn
    }
}
