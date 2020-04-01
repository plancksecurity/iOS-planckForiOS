//
//  UnitTestUtils.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 11.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Unit test (in contrast to integration test) specific utils.
struct UnitTestUtils {

    /// The maximum wait time for unit tests that are synchronous.
    static let waitTime: TimeInterval = 0.01

    /// The maximum wait time for unit tests that are asynchronous.
    //!!!: dirty!
    static let asyncWaitTime: TimeInterval = 1.0
}
