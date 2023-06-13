//
//  instalAndLaunchPlanck.swift
//  planckForiOSUITests
//
//  Created by Khurram Sheikh on 7/6/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//
import XCTest

final class LaunchAndTerminatePlanck: XCTestCase {

    let common = CommonFunctions()
    
    func testAppLaunchAndTerminate() {
        common.appLaunch()
        Thread.sleep(forTimeInterval: 10)
        common.appTerminate()
    }
    
    }
