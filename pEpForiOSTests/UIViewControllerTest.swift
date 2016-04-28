//
//  UIViewControllerTest.swift
//  pEpForiOS
//
//  Created by ana on 27/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import pEpForiOS

class UIViewControllerTest: XCTestCase {

    var model = ModelUserInfoTable(emailTextExist: false, passwordTextExist: false)


    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        let model = ModelUserInfoTable.init(emailTextExist: false, passwordTextExist: false)
        XCTAssertFalse(model.shouldEnableNextButton())
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        let vc = UserInfoTableView.init()
        var prove = model.passwordTextExist
    }

}

