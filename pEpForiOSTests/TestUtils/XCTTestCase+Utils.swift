//
//  XCTTestCase+Utils.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

extension XCTestCase {

    // MARK: - Expectation

    public func expectation(named name: String = #function,
                            inverted: Bool = false) -> XCTestExpectation {
        let description = name + " \(inverted)"
        let createe = expectation(description: description)
        createe.isInverted = inverted
        return createe
    }
}
