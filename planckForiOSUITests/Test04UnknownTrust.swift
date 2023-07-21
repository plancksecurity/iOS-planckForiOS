//
//  Test04UnknownTrust.swift
//  planckForiOSUITests
//
//  Created by Nasr on 21/07/2023.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation

import XCTest

final class Test04UnknownTrust: XCTestCase {
    
    
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

    func test04UnknownTrust() {
        
        
        let composeButton = app.buttons [UIStrings.composeButton]
        _=composeButton.waitForExistence(timeout: 3)
        composeButton.tap()
        
        // let toTextField = app.textFields
        
        let tapTo = app.staticTexts[UIStrings.to]
        _=tapTo.waitForExistence(timeout: 5)
        tapTo.tap()
        
        
        app.typeText(UIStrings.UknownTrustEmail)
        Thread.sleep(forTimeInterval: 10)
        
        let tablesQuery = app.tables
        _=tablesQuery.element.waitForExistence(timeout: 3)
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Cc/Bcc:"]/*[[".cells.staticTexts[\"Cc\/Bcc:\"]",".staticTexts[\"Cc\/Bcc:\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
       
        // Write the code to match the images privacy status
        
        
        app.tables.cells.containing(.staticText, identifier:UIStrings.subject).children(matching: .textView).element.tap()
        app.typeText(UIStrings.subjectText)
        
        let pepforiosComposeviewNavigationBar = app.navigationBars["pEpForiOS.ComposeView"]
        
        
        let emailTextViewTextView = app.tables/*@START_MENU_TOKEN@*/.textViews["Email Text View"]/*[[".cells.textViews[\"Email Text View\"]",".textViews[\"Email Text View\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        emailTextViewTextView.tap()
        emailTextViewTextView.tap()
        app.typeText(UIStrings.emailBody)
        
        let unknownTrustImage = pepforiosComposeviewNavigationBar.images["Unknown Trust"]
        
        if(unknownTrustImage.exists){
            print("Unknown Trust")
            XCTAssertTrue(true)
        }else
        {
            XCTAssert(false)
        }
        
        
        //app.buttons[UIStrings.sendText].tap()
        
                        
        //Thread.sleep(forTimeInterval: 5)
        
        //app.buttons[UIStrings.yesText].tap()
        
    }
    
    
    
    
   
}
