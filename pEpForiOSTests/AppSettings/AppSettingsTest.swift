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

    let address1 = "mb@pep.security"
    let address2 = "iostest017@pep.security"
    let address3 = "iostest018@pep.security"

    let folderName1 = "Inbox.My Inbox"
    let folderName2 = "Inbox.My Inbox.Subfolder"
    let folderName3 = "Inbox.My Inbox.Subfolder.Subfolder"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: appGroupIdentifier)
    }

    func testDefaultAccountSettings() {
        let expectedFalse = AppSettings.shared.collapsedState(forAccountWithAddress: address1)
        XCTAssertFalse(expectedFalse)
    }

    func testSetAccountCollapsedState() {
        //Set a few collapsing states
        AppSettings.shared.setAccountCollapsedState(address: address2, isCollapsed: true)
        AppSettings.shared.setAccountCollapsedState(address: address3, isCollapsed: false)
        AppSettings.shared.setAccountCollapsedState(address: address1, isCollapsed: true)

        //Check each
        let address1CollapsedState = AppSettings.shared.collapsedState(forAccountWithAddress: address1)
        XCTAssertTrue(address1CollapsedState)

        let address3CollapsedState = AppSettings.shared.collapsedState(forAccountWithAddress: address3)
        XCTAssertFalse(address3CollapsedState)

        let address2CollapsedState = AppSettings.shared.collapsedState(forAccountWithAddress: address2)
        XCTAssertTrue(address2CollapsedState)

        // Override value of one of them
        AppSettings.shared.setAccountCollapsedState(address: address1, isCollapsed: false)
        let address1CollapsedStateAgain = AppSettings.shared.collapsedState(forAccountWithAddress: address1)
        XCTAssertFalse(address1CollapsedStateAgain)
    }

    func testSetFolderCollapsedState() {
        let folder1CollapsingState = AppSettings.shared.collapsedState(forFolderNamed: folderName1, ofAccountWithAddress: address1)
        XCTAssertFalse(folder1CollapsingState)
        AppSettings.shared.setFolderCollapsedState(address: address1,
                                                   folderName: folderName1,
                                                   isCollapsed: true)
        let newFolder1CollapsingState = AppSettings.shared.collapsedState(forFolderNamed: folderName1, ofAccountWithAddress: address1)
        XCTAssertTrue(newFolder1CollapsingState)
    }

    func testSetFoldersCollapsedState() {
        let folder1CollapsingState = AppSettings.shared.collapsedState(forFolderNamed: folderName1, ofAccountWithAddress: address1)
        let folder2CollapsingState = AppSettings.shared.collapsedState(forFolderNamed: folderName2, ofAccountWithAddress: address1)
        let folder3CollapsingState = AppSettings.shared.collapsedState(forFolderNamed: folderName3, ofAccountWithAddress: address1)
        XCTAssertFalse(folder1CollapsingState)
        XCTAssertFalse(folder2CollapsingState)
        XCTAssertFalse(folder3CollapsingState)

        AppSettings.shared.setFolderCollapsedState(address: address1,
                                                   folderName: folderName1,
                                                   isCollapsed: true)
        AppSettings.shared.setFolderCollapsedState(address: address1,
                                                   folderName: folderName2,
                                                   isCollapsed: true)

        let newFolder1CollapsingState = AppSettings.shared.collapsedState(forFolderNamed: folderName1, ofAccountWithAddress: address1)
        XCTAssertTrue(newFolder1CollapsingState)
        let newFolder2CollapsingState = AppSettings.shared.collapsedState(forFolderNamed: folderName2, ofAccountWithAddress: address1)
        XCTAssertTrue(newFolder2CollapsingState)
        let newFolder3CollapsingState = AppSettings.shared.collapsedState(forFolderNamed: folderName3, ofAccountWithAddress: address1)
        XCTAssertFalse(newFolder3CollapsingState)
    }

    func testSetFolderCollapsedStateSetsAccountUncollapsedByDefault() {
        AppSettings.shared.setFolderCollapsedState(address: address1,
                                                   folderName: folderName2,
                                                   isCollapsed: true)

        let expectedFalse = AppSettings.shared.collapsedState(forAccountWithAddress: address1)
        XCTAssertFalse(expectedFalse)
    }

    func testRemoveAll() {
        AppSettings.shared.setFolderCollapsedState(address: address1,
                                                   folderName: folderName2,
                                                   isCollapsed: true)

        AppSettings.shared.removeCollapsingStateOfAccountWithAddress(address: address1)
        let address1CollapsedState = AppSettings.shared.collapsedState(forAccountWithAddress: address1)
        XCTAssertFalse(address1CollapsedState)
    }

}
