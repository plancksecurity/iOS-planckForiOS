//
//  ObserverDelegate.swift
//  MessageModel
//
//  Created by Xavier Algarra on 24/11/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

import XCTest
import MessageModel

open class ObserverDelegate: ModelObserverDelegate {
    let expSaved: XCTestExpectation?

    public init(expSaved: XCTestExpectation?) {
        self.expSaved = expSaved
    }

    public func didSaveAll() {
        expSaved?.fulfill()
    }
}
