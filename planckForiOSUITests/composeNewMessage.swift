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
        
//        func AppTerminate(){
//            app.terminate()
//        }
    
    func testComposeNewMessage() {
        AppLaunch()
        
        let composeButton = app.buttons [UIStrings.composeButton]
        _=composeButton.waitForExistence(timeout: 5)
        composeButton.tap()
        
        // let toTextField = app.textFields
        
        let tapTo = app.staticTexts["To:"]
        _=tapTo.waitForExistence(timeout: 2)
        tapTo.tap()
        
        app.typeText("qa@sq.pep.security")
  
        
      
        
        let tablesQuery = app.tables
        
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Cc/Bcc:"]/*[[".cells.staticTexts[\"Cc\/Bcc:\"]",".staticTexts[\"Cc\/Bcc:\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
       
        app.tables.cells.containing(.staticText, identifier:"Subject:").children(matching: .textView).element.tap()
        app.typeText("This is my Subject")
        
        
        app.tables.cells.containing(.textView, identifier:"Email Text View").children(matching: .textView).element.tap()
        app.typeText("This is email body, and I am writing my first message.")
        
        app.buttons["Send"].tap()
        
        app.buttons["YES"].tap()
                        
        Thread.sleep(forTimeInterval: 10)
        
        
       
    }
}
