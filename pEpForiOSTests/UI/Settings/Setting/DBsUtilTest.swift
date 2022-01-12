//
//  DBsUtilTest.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 12/1/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class DBsUtilTest: XCTestCase {

    private let exportDBQueueLabel = "test.security.pep.SettingsViewModel.databasesIOQueue"

    func testDBExport() throws {

        DispatchQueue(label: exportDBQueueLabel, qos: .userInitiated).async { [weak self] in
            guard let me = self else {
                DispatchQueue.main.async {
                    XCTFail("Lost myself")
                }
                return
            }

            var isDirectory:ObjCBool = true
            guard let path = me.getDBDestinationDirectoryURL()?.path else {
                DispatchQueue.main.async {
                    XCTFail("Destination url not found")
                }
                return
            }
            let directoryExistsBeforeExportDB = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            //Must be called on the main thread as it comes from XCUIScreen
            DispatchQueue.main.async {
                XCTAssertFalse(directoryExistsBeforeExportDB)
            }


            do {
                try DBsUtil.exportDatabases()
            } catch {
                DispatchQueue.main.async {
                    XCTFail("Something fail")
                }
            }

            let directoryExistsAfterExportDB = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            //Must be called on the main thread as it comes from XCUIScreen
            DispatchQueue.main.async {
                XCTAssert(directoryExistsAfterExportDB)
            }

        }
    }

    override func tearDown() {
        super.tearDown()

        DispatchQueue(label: exportDBQueueLabel, qos: .userInitiated).async { [weak self] in
            guard let me = self else {
                DispatchQueue.main.async {
                    XCTFail("Lost myself")
                }
                return
            }

            guard let url = me.getDBDestinationDirectoryURL() else {
                DispatchQueue.main.async {
                    XCTFail("Destination url not found")
                }

                return
            }
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                DispatchQueue.main.async {
                    XCTFail("Something went wrong")
                }

            }
        }
    }
}

extension DBsUtilTest {

    private func getDBDestinationDirectoryURL() -> URL? {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard var docUrl = documentsUrl else {
            XCTFail("Something fail")
            return nil
        }
        docUrl.appendPathComponent("db-export")
        return docUrl
    }
}
