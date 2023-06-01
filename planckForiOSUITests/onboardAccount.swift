//
//  onboardAccount.swift
//  planckForiOSUITests
//
//  Created by Khurram Sheikh on 29/5/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import XCTest

final class onboardAccount: XCTestCase {

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
    
        func testLoginFunctionality(){
            
            AppLaunch() // Launch the App
            
            let tapOther = app.staticTexts[UIStrings.signInWithPassword]
            _=tapOther.waitForExistence(timeout: 10)
            tapOther.tap()
            
            let tapEmail = app.textFields[UIStrings.emailAddressTextfield]
            _=tapEmail.waitForExistence(timeout: 5)
            tapEmail.tap()
            tapEmail.typeText(UIStrings.emailAddress)
            
            let tapPassword = app.scrollViews.otherElements.secureTextFields[UIStrings.emailPasswordTextfield]
            _=tapPassword.waitForExistence(timeout: 5)
            tapPassword.tap()
            tapPassword.typeText(UIStrings.emailPassword)
            
            
            let tapDisplayName = app.scrollViews.otherElements.textFields[UIStrings.displayNameTextField]
            _=tapDisplayName.waitForExistence(timeout: 5)
            tapDisplayName.tap()
            tapDisplayName.typeText(UIStrings.displayName)
            
            
            let tapLogIn = app.scrollViews.otherElements.buttons[UIStrings.logIn]
            _=tapLogIn.waitForExistence(timeout: 5)
            tapLogIn.tap()
            
            Thread.sleep(forTimeInterval: 20)
            let okButton = app.buttons[UIStrings.okButton]
            
            if okButton.exists {
                okButton.tap()
                
                // Manual Account Setup
                let manualSetupButton = app.buttons[UIStrings.manualConfigButton]
                if manualSetupButton.exists {
                    manualSetupButton.tap()
                    let nextButton = app.buttons[UIStrings.nextButton]
                    _=nextButton.waitForExistence(timeout: 5)
                    nextButton.tap()
                    
                    let tapServer = app.textFields[UIStrings.serverTextfield]
                    _=tapServer.waitForExistence(timeout: 5)
                    tapServer.tap()
                    tapServer.typeText(UIStrings.serverName)
                    
                    let secondNextButton = app.buttons[UIStrings.nextButton]
                    _=secondNextButton.waitForExistence(timeout: 5)
                    secondNextButton.tap()
                    
                    
                    let secondTapServer = app.textFields[UIStrings.serverTextfield]
                    _=secondTapServer.waitForExistence(timeout: 5)
                    secondTapServer.tap()
                    secondTapServer.typeText(UIStrings.serverName)
                    
                    let finishButton = app.buttons[UIStrings.finishButton]
                    _=finishButton.waitForExistence(timeout: 5)
                    finishButton.tap()
                    
                    
                    Thread.sleep(forTimeInterval: 20)
                    
                    // Or locate the label by its label text
                    let label = app.staticTexts[UIStrings.inboxLable]
                    
                    // Perform actions on the label
                    if label.exists {
                        
                        // Access the label's value or interact with it
                        XCTAssertTrue(label.exists)
                    } else {
                        XCTFail("Failed to Login Successfully.")
                    }
                    
                    
                }
                
                
            }   else {
                let label = app.staticTexts[UIStrings.inboxLable]
                
                // Perform actions on the label
                if label.exists {
                    
                    // Access the label's value or interact with it
                    XCTAssertTrue(label.exists)
                } else {
                    XCTFail("Failed to Login Successfully.")
                }
                }
            
            //print(tapOther)
            
            //testAppTerminate()
        }

}
