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
        _=composeButton.waitForExistence(timeout: 3)
        composeButton.tap()
        
        // let toTextField = app.textFields
        
        let tapTo = app.staticTexts[UIStrings.to]
        _=tapTo.waitForExistence(timeout: 5)
        tapTo.tap()
        
        let common = commonFunc()
        let randomBot = common.generateRandomBot()
        app.typeText(randomBot)
        Thread.sleep(forTimeInterval: 10)
  
        
        let tablesQuery = app.tables
        _=tablesQuery.element.waitForExistence(timeout: 3)
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Cc/Bcc:"]/*[[".cells.staticTexts[\"Cc\/Bcc:\"]",".staticTexts[\"Cc\/Bcc:\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
       
        app.tables.cells.containing(.staticText, identifier:UIStrings.subject).children(matching: .textView).element.tap()
        app.typeText(UIStrings.subjectText)
        
        
      
        app.tables.cells.containing(.textView, identifier:UIStrings.emailTextView).children(matching: .textView).element.tap()
        app.typeText(UIStrings.emailBody)
        
        app.buttons[UIStrings.sendText].tap()
        
                        
        Thread.sleep(forTimeInterval: 5)
        
        app.buttons[UIStrings.yesText].tap()
        
        // Check Sent Emails
        XCUIApplication().navigationBars["Inbox"].buttons["Mailboxes"].tap()
        
        
      
        AppTerminate() // App Close
        
        
        
       
    }
    
    func testSendEmail() {
        
        
        AppLaunch()
        
        app.toolbars["Toolbar"].buttons["Compose Button"].tap()
        app.alerts["“planck” Would Like to Access Your Contacts"].scrollViews.otherElements.buttons["OK"].tap()
        
        let tablesQuery = app.tables
        let textView = tablesQuery.cells.containing(.staticText, identifier:"Subject:").children(matching: .textView).element
        textView.tap()
        app.typeText(UIStrings.subjectText)
       
        
        
        let emailTextViewTextView = tablesQuery/*@START_MENU_TOKEN@*/.textViews["Email Text View"]/*[[".cells.textViews[\"Email Text View\"]",".textViews[\"Email Text View\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        emailTextViewTextView.tap()
        emailTextViewTextView.tap()
        emailTextViewTextView.tap()
        app.navigationBars["pEpForiOS.ComposeView"]/*@START_MENU_TOKEN@*/.buttons["Send Button"].press(forDuration: 1.1);/*[[".buttons[\"Send\"]",".tap()",".press(forDuration: 1.1);",".buttons[\"Send Button\"]"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/
        app.buttons["YES"].tap()
        

        
        AppTerminate() // App Terminate
    }
}
