//
//  instalAndLaunchPlanck.swift
//  planckForiOSUITests
//
//  Created by Khurram Sheikh on 7/6/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//
import XCTest

final class Test01LaunchAndTerminatePlanck: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()
    }
    
    
    override  func tearDown() {
        app.terminate()
    }
    
    
    func test01AppLaunchAndTerminate() {
        Thread.sleep(forTimeInterval: 10)
    }
    
}
