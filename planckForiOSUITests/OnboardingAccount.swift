//
//  onboardAccount.swift
//  planckForiOSUITests
//
//  Created by Khurram Sheikh on 29/5/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import XCTest

final class Test02OnboaringdAccount: XCTestCase {

    let common = CommonFunctions()
    

        
    
    func test02LoginFunctionality(){
        
        
        common.appLaunch() // Launch the App
        
        let tapOther = common.app.staticTexts[UIStrings.signInWithPassword]
        _=tapOther.waitForExistence(timeout: 10)
        tapOther.tap()
        
        let tapEmail = common.app.textFields[UIStrings.emailAddressTextfield]
        _=tapEmail.waitForExistence(timeout: 5)
        tapEmail.tap()
        tapEmail.typeText(UIStrings.emailAddress)
        
        let tapPassword = common.app.scrollViews.otherElements.secureTextFields[UIStrings.emailPasswordTextfield]
        _=tapPassword.waitForExistence(timeout: 5)
        tapPassword.tap()
        tapPassword.typeText(UIStrings.emailPassword)
        
        
        let tapDisplayName = common.app.scrollViews.otherElements.textFields[UIStrings.displayNameTextField]
        _=tapDisplayName.waitForExistence(timeout: 5)
        tapDisplayName.tap()
        tapDisplayName.typeText(UIStrings.displayName)
        
        
        let tapLogIn = common.app.scrollViews.otherElements.buttons[UIStrings.logIn]
        _=tapLogIn.waitForExistence(timeout: 5)
        tapLogIn.tap()
        
        Thread.sleep(forTimeInterval: 10)
        let okButton = common.app.buttons[UIStrings.okButton]
        
        if okButton.exists {
            okButton.tap()
            manualSetup()
        }   else {
            let label = common.app.staticTexts[UIStrings.inboxLable]
            
            // Perform actions on the label
            if label.exists {
                
                // Access the label's value or interact with it
                XCTAssertTrue(label.exists)
            } else {
                XCTFail("Failed to Login Successfully.")
            }
        }
        
        //print(tapOther)
        
        //Thread.sleep(forTimeInterval: 5)
        
        //appTerminate()
    }
    
    // For Manual Account Setup functionality
    func manualSetup() {
        
        // Manual Account Setup
        let manualSetupButton = common.app.buttons[UIStrings.manualConfigButton]
        if manualSetupButton.exists {
            manualSetupButton.tap()
            let nextButton = common.app.buttons[UIStrings.nextButton]
            _=nextButton.waitForExistence(timeout: 5)
            nextButton.tap()
            
            let tapServer = common.app.textFields[UIStrings.serverTextfield]
            _=tapServer.waitForExistence(timeout: 5)
            tapServer.tap()
            tapServer.typeText(UIStrings.serverName)
            
            let secondNextButton = common.app.buttons[UIStrings.nextButton]
            _=secondNextButton.waitForExistence(timeout: 5)
            secondNextButton.tap()
            
            
            let secondTapServer = common.app.textFields[UIStrings.serverTextfield]
            _=secondTapServer.waitForExistence(timeout: 5)
            secondTapServer.tap()
            secondTapServer.typeText(UIStrings.serverName)
            
            let finishButton = common.app.buttons[UIStrings.finishButton]
            _=finishButton.waitForExistence(timeout: 5)
            finishButton.tap()
            
            
            Thread.sleep(forTimeInterval: 10)
            
            // Or locate the label by its label text
            let label = common.app.staticTexts[UIStrings.inboxLable]
            
            // Perform actions on the label
            if label.exists {
                
                // Access the label's value or interact with it
                XCTAssertTrue(label.exists)
            } else {
                XCTFail("Failed to Login Successfully.")
            }
            
            
        }

    }

}
