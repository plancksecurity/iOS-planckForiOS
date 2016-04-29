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
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testButtonNextScreenCorrectBehaviorWithoutPasswordAndEmail() {
        let model = ModelUserInfoTable.init(emailTextExist: false, passwordTextExist: false)
        XCTAssertFalse(model.shouldEnableNextButton())
    }

    func testButtonNextScreenCorrectBehaviorWithoutPassword() {
        let model = ModelUserInfoTable.init(emailTextExist: true, passwordTextExist: false)
        XCTAssertFalse(model.shouldEnableNextButton())
    }

    func testButtonNextScreenCorrectBehaviorWithoutEmail() {
        let model = ModelUserInfoTable.init(emailTextExist: false, passwordTextExist: true)
        XCTAssertFalse(model.shouldEnableNextButton())
    }

    func testButtonNextScreenCorrectBehaviorWithAllData() {
        let model = ModelUserInfoTable.init(emailTextExist: true, passwordTextExist: true)
        XCTAssertTrue(model.shouldEnableNextButton())
    }

    func testPerformanceExample() {
        let vc = UserInfoTableView.init()
        XCTAssertNotNil(vc)
    }

}

