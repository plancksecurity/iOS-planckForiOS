//
//  ResetTrustViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Xavier Algarra on 02/09/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
@testable import MessageModel

class ResetTrustViewModelTest: AccountDrivenTestBase {

    func testIOS2395() {
        //given
        let expectedNumberOfSections = 5
        let expectedIndexTitles = ["A","B","C","D","N"]
        let numberConflictiveToExistingSection = 1
        let numberidConflictiveToNewSection = 4
        let expectedNumberOfRowsInConflictiveSections = 2
        let expectedTitleForNewConflictiveRow = expectedIndexTitles[4]
        let id1 = Identity(address: "a@mail.com", userName: "a")
        id1.session.commit()
        let id2 = Identity(address: "b@mail.com", userName: "b")
        id2.session.commit()
        let id3 = Identity(address: "c@mail.com", userName: "c")
        id3.session.commit()
        let id4 = Identity(address: "d@mail.com", userName: "d")
        id4.session.commit()
        // as Ｂ is like B it's expected that this identity appears in section with title B
        let idConflictiveToExistingSection = Identity(address: "conflictive1@mail.com", userName: "Ｂitcoin")
        idConflictiveToExistingSection.session.commit()
        // as Ｎ is like N it's expected that this identity creates the section with title N
        let idConflictiveToNewSection = Identity(address: "conflictive2@mail.com", userName: "Ｎever")
        idConflictiveToNewSection.session.commit()
        
        //when
        let vm = ResetTrustViewModel()
        
        //then
        XCTAssertEqual(expectedNumberOfSections, vm.numberOfSections())
        XCTAssertEqual(expectedIndexTitles, vm.indexTitles())
        XCTAssertEqual(vm.numberOfRowsIn(section: numberConflictiveToExistingSection), expectedNumberOfRowsInConflictiveSections)
        XCTAssertEqual(vm.titleForSections(index: numberidConflictiveToNewSection), expectedTitleForNewConflictiveRow)
    }

}
