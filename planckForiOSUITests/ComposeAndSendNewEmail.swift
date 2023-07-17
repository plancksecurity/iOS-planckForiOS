//
//  composeNewMessage.swift
//  planckForiOSUITests
//
//  Created by Khurram Sheikh on 29/5/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import XCTest

final class Test03ComposeAndSendNewEmail: XCTestCase {

    func test03ComposeAndSendNewEmail() {
        
        let common = CommonFunctions()
        
        common.appLaunch()
        
        
        let composeButton = common.app.buttons [UIStrings.composeButton]
        _=composeButton.waitForExistence(timeout: 3)
        composeButton.tap()
        
        // let toTextField = app.textFields
        
        let tapTo = common.app.staticTexts[UIStrings.to]
        _=tapTo.waitForExistence(timeout: 5)
        tapTo.tap()
        
        
        let randomBot = common.generateRandomBot()
        common.app.typeText(randomBot)
        Thread.sleep(forTimeInterval: 10)
  
        
        let tablesQuery = common.app.tables
        _=tablesQuery.element.waitForExistence(timeout: 3)
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Cc/Bcc:"]/*[[".cells.staticTexts[\"Cc\/Bcc:\"]",".staticTexts[\"Cc\/Bcc:\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
       
        // Write the code to match the images privacy status
        
        
        common.app.tables.cells.containing(.staticText, identifier:UIStrings.subject).children(matching: .textView).element.tap()
        common.app.typeText(UIStrings.subjectText)
        
        
      
        let tableemailboday = common.app.tables.cells.containing(.textView, identifier:UIStrings.emailTextView).children(matching: .textView).element.tap()
        
        common.app.tables/*@START_MENU_TOKEN@*/.textViews["Email Text View"]/*[[".cells.textViews[\"Email Text View\"]",".textViews[\"Email Text View\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        common.app.typeText(UIStrings.emailBody)
        
        common.app.buttons[UIStrings.sendText].tap()
        
                        
        Thread.sleep(forTimeInterval: 5)
        
        common.app.buttons[UIStrings.yesText].tap()
        
        // Check Sent Emails
        common.app.navigationBars["Inbox"].buttons["Mailboxes"].tap()
        
        
        common.appTerminate() // App Close
        
    }
    
    
    
    
   
}
