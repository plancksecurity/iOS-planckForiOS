//
//  ContactsSelectionViewModelTests.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 15/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS


// WIP
class ContactsSelectionViewModelTests: XCTestCase {

    func testGetContactsOnlyWithEmail() {
        let vm = ContactsSelectionViewModel()
        let contacts = vm.getContactsOnlyWithEmail()
        XCTAssertTrue(contacts.count > 0, "getContacts failed!")
    }

}
