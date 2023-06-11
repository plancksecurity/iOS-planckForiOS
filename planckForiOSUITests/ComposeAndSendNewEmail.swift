//
//  composeNewMessage.swift
//  planckForiOSUITests
//
//  Created by Khurram Sheikh on 29/5/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import XCTest

final class ComposeAndSendNewEmail: XCTestCase {

    let app = XCUIApplication()
        
        func appLaunch(){
            app.launch()
        }
        
        func appTerminate(){
            app.terminate()
        }
    
    func testComposeAndSendNewEmail() {
        
        appLaunch()
        
        
        let composeButton = app.buttons [UIStrings.composeButton]
        _=composeButton.waitForExistence(timeout: 3)
        composeButton.tap()
        
        // let toTextField = app.textFields
        
        let tapTo = app.staticTexts[UIStrings.to]
        _=tapTo.waitForExistence(timeout: 5)
        tapTo.tap()
        
        let common = CommonFunctions()
        let randomBot = common.generateRandomBot()
        app.typeText(randomBot)
        Thread.sleep(forTimeInterval: 10)
  
        
        let tablesQuery = app.tables
        _=tablesQuery.element.waitForExistence(timeout: 3)
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Cc/Bcc:"]/*[[".cells.staticTexts[\"Cc\/Bcc:\"]",".staticTexts[\"Cc\/Bcc:\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
       
        app.tables.cells.containing(.staticText, identifier:UIStrings.subject).children(matching: .textView).element.tap()
        app.typeText(UIStrings.subjectText)
        
        
      
        let tableemailboday = app.tables.cells.containing(.textView, identifier:UIStrings.emailTextView).children(matching: .textView).element.tap()
        
        app.tables/*@START_MENU_TOKEN@*/.textViews["Email Text View"]/*[[".cells.textViews[\"Email Text View\"]",".textViews[\"Email Text View\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.typeText(UIStrings.emailBody)
        
        app.buttons[UIStrings.sendText].tap()
        
                        
        Thread.sleep(forTimeInterval: 5)
        
        app.buttons[UIStrings.yesText].tap()
        
        // Check Sent Emails
        XCUIApplication().navigationBars["Inbox"].buttons["Mailboxes"].tap()
        
        
        appTerminate() // App Close
        
    }
    
   
}
