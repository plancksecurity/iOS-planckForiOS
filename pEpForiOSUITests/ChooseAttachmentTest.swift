//
//  ChooseAttachmentTest.swift
//  pEpForiOS
//
//  Created by ana on 21/9/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

class ChooseAttachmentTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
       
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAttachImage() {
        XCUIDevice.sharedDevice().orientation = .FaceUp
        XCUIDevice.sharedDevice().orientation = .FaceUp
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Inbox (misifu@miau.xyz)"].tap()
        app.toolbars.buttons["Compose"].tap()
        app.navigationBars["pEpForiOS.ComposeView"].buttons["Add"].tap()
        app.sheets["AttachedFiles"].collectionViews.buttons["Photo"].tap()
        tablesQuery.buttons["Moments"].tap()
        app.collectionViews["PhotosGridView"].cells["Live Photo, Portrait, 17 de septiembre 13:10"].tap()
        tablesQuery.childrenMatchingType(.Cell).elementBoundByIndex(4).childrenMatchingType(.TextView).element.tap()
        
      

    }

}
