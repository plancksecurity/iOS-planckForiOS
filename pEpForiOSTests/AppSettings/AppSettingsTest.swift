//
//  CollapsingFoldersAndAccountsTest.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 1/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS
import pEp4iosIntern

class AppSettingsTest: XCTestCase {

    let address1 = "some@example.com"
    let address2 = "iostest017@pep.security"
    let address3 = "iostest018@pep.security"

    let folderName1 = "Inbox.My Inbox"
    let folderName2 = "Inbox.My Inbox.Subfolder"
    let folderName3 = "Inbox.My Inbox.Subfolder.Subfolder"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: kAppGroupIdentifier)
    }

    func testDefaultAccountSettings() {
        let expectedFalse = AppSettings.shared.folderViewCollapsedState(forAccountWith: address1)
        XCTAssertFalse(expectedFalse)
    }

    func testSetAccountCollapsedState() {
        //Set a few collapsing states
        AppSettings.shared.setFolderViewCollapsedState(forAccountWith: address2, to: true)
        AppSettings.shared.setFolderViewCollapsedState(forAccountWith: address3, to: false)
        AppSettings.shared.setFolderViewCollapsedState(forAccountWith: address1, to: true)

        //Check each
        let address1CollapsedState = AppSettings.shared.folderViewCollapsedState(forAccountWith: address1)
        XCTAssertTrue(address1CollapsedState)

        let address3CollapsedState = AppSettings.shared.folderViewCollapsedState(forAccountWith: address3)
        XCTAssertFalse(address3CollapsedState)

        let address2CollapsedState = AppSettings.shared.folderViewCollapsedState(forAccountWith: address2)
        XCTAssertTrue(address2CollapsedState)

        // Override value of one of them
        AppSettings.shared.setFolderViewCollapsedState(forAccountWith: address1, to: false)
        let address1CollapsedStateAgain = AppSettings.shared.folderViewCollapsedState(forAccountWith: address1)
        XCTAssertFalse(address1CollapsedStateAgain)
    }

    func testsetFolderViewCollapsedState() {
        let folder1CollapsingState = AppSettings.shared.folderViewCollapsedState(forFolderNamed: folderName1, ofAccountWith: address1)
        XCTAssertFalse(folder1CollapsingState)
        AppSettings.shared.setFolderViewCollapsedState(forFolderNamed: folderName1, ofAccountWith: address1, to: true)
        let newFolder1CollapsingState = AppSettings.shared.folderViewCollapsedState(forFolderNamed: folderName1, ofAccountWith: address1)
        XCTAssertTrue(newFolder1CollapsingState)
    }

    func testSetFoldersCollapsedState() {
        let folder1CollapsingState = AppSettings.shared.folderViewCollapsedState(forFolderNamed: folderName1, ofAccountWith: address1)
        let folder2CollapsingState = AppSettings.shared.folderViewCollapsedState(forFolderNamed: folderName2, ofAccountWith: address1)
        let folder3CollapsingState = AppSettings.shared.folderViewCollapsedState(forFolderNamed: folderName3, ofAccountWith: address1)
        XCTAssertFalse(folder1CollapsingState)
        XCTAssertFalse(folder2CollapsingState)
        XCTAssertFalse(folder3CollapsingState)

        AppSettings.shared.setFolderViewCollapsedState(forFolderNamed: folderName1, ofAccountWith: address1, to: true)
        AppSettings.shared.setFolderViewCollapsedState(forFolderNamed: folderName2, ofAccountWith: address1, to: true)

        let newFolder1CollapsingState = AppSettings.shared.folderViewCollapsedState(forFolderNamed: folderName1, ofAccountWith: address1)
        XCTAssertTrue(newFolder1CollapsingState)
        let newFolder2CollapsingState = AppSettings.shared.folderViewCollapsedState(forFolderNamed: folderName2, ofAccountWith: address1)
        XCTAssertTrue(newFolder2CollapsingState)
        let newFolder3CollapsingState = AppSettings.shared.folderViewCollapsedState(forFolderNamed: folderName3, ofAccountWith: address1)
        XCTAssertFalse(newFolder3CollapsingState)
    }

    func testSetFolderCollapsedStateSetsAccountUncollapsedByDefault() {
        AppSettings.shared.setFolderViewCollapsedState(forFolderNamed: folderName2, ofAccountWith: address1, to: true)
        let expectedFalse = AppSettings.shared.folderViewCollapsedState(forAccountWith: address1)
        XCTAssertFalse(expectedFalse)
    }

    func testRemoveAll() {
        AppSettings.shared.setFolderViewCollapsedState(forFolderNamed: folderName2, ofAccountWith: address1, to: true)
        AppSettings.shared.removeFolderViewCollapsedStateOfAccountWith(address: address1)
        let address1CollapsedState = AppSettings.shared.folderViewCollapsedState(forAccountWith: address1)
        XCTAssertFalse(address1CollapsedState)
    }
}
