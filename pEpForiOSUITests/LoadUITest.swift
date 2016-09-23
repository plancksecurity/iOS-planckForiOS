//
//  LoadUITest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

class LoadUITest: XCTestCase {
    override func setUp() {
        super.setUp()
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test.
        // Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCancelComposeSaveDraft() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.childrenMatchingType(.Cell).elementBoundByIndex(0).tap()

        while true {
            let composeButton = app.toolbars.buttons["Compose"]
            composeButton.tap()
            let tf = tablesQuery.textFields["Subject"]
            tf.tap()
            tf.typeText("Some Subject")

            let cancelButton = app.navigationBars["pEpForiOS.ComposeView"].buttons["Cancel"]
            cancelButton.tap()

            let saveDraftButton = app.sheets.collectionViews.buttons["Save Draft"]
            saveDraftButton.tap()
        }
    }
}