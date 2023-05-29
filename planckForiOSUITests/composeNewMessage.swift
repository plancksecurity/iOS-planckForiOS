//
//  composeNewMessage.swift
//  planckForiOSUITests
//
//  Created by Khurram Sheikh on 29/5/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import XCTest

final class composeNewMessage: XCTestCase {

    let app = XCUIApplication()
        
        override func setUpWithError() throws {
            // Put setup code here. This method is called before the invocation of each test method in the class.
            
            // In UI tests it is usually best to stop immediately when a failure occurs.
            continueAfterFailure = false
            
            // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        }
        
        override func tearDownWithError() throws {
            // Put teardown code here. This method is called after the invocation of each test method in the class.
        }
        
        func AppLaunch(){
            app.launch()
        }
        
        func AppTerminate(){
            app.terminate()
        }
    
    func testComposeNewMessage() {
        AppLaunch()
        
        let composeButton = app.buttons [UIStrings.composeButton]
        _=composeButton.waitForExistence(timeout: 5)
        composeButton.tap()
        
        // let toTextField = app.textFields
        
        Thread.sleep(forTimeInterval: 20)
        print("Compose Opened")
    }
}
