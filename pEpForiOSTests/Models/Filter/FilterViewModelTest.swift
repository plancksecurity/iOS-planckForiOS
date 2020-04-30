//IOS-2241 DOES NOT COMPILE
////
////  FilterViewModelTest.swift
////  pEpForiOSTests
////
////  Created by Borja González de Pablo on 02/10/2018.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//
//@testable import pEpForiOS
//@testable import MessageModel
//
//class FilterViewModelTest: CoreDataDrivenTestBase {
//
//    override func setUp() {
//        super.setUp()
//
//    }
//
////    //!!!: this has to be redone when FilterViewModel is done
////    func testCreateCorrectAccountCell() {
////        givenThereAreTwoAccounts()
////        let accountNumber = 2
////        let viewmodel = FilterViewModel(type: .accouts)
////        XCTAssertEqual(accountNumber, viewmodel.count)
////    }
////
////    func testCreateCorrectIncludeCells() {
////        let includeFilters = [UnreadFilter.self, FlaggedFilter.self]
////        let viewmodel = FilterViewModel(type: .include)
////        XCTAssertEqual(includeFilters.count, viewmodel.count)
////    }
////
////    func testCreateCorrectOtherCells() {
////        let otherFilters = [AttachmentFilterTest.self]
////        let viewmodel = FilterViewModel(type: .other)
////        XCTAssertEqual(otherFilters.count, viewmodel.count)
////    }
////
////
////    //MARK: Initialization
////    func givenThereAreTwoAccounts() {
////        _ = SecretTestData().createWorkingCdAccount(number: 1)
////        moc.saveAndLogErrors()
////    }
////}
