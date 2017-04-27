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
            invokeObservers()
        }
    }

    init(value: T?) {
        self.value = value
    }

    convenience init() {
        self.init(value: nil)
    }

    public func observe(fn: @escaping ObservableFunc<T>) {
        observers.append(ObservableFuncWrapper(fn: fn))
    }

    private func invokeObservers() {
        for ob in observers {
            ob.fn(value)
        }
    }

    private var observers = [ObservableFuncWrapper<T>]()
}

typealias ObservableFunc<T> = (_ newValue: T?) -> Void

class ObservableFuncWrapper<T>: AnyObject {
    let fn: ObservableFunc<T>

    init(fn: @escaping ObservableFunc<T>) {
        self.fn = fn
    }
}
