//
//  BackgroundTaskManagerTest.swift
//  MessageModelTests
//
//  Created by Andreas Buff on 01.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class BackgroundTaskManagerTest: XCTestCase {

    var testee = BackgroundTaskManager()

    override func setUp() {
        super.setUp()
        testee = BackgroundTaskManager()
    }

    // MARK: - startBackgroundTask

    func testStartBackgroundTask_valid() {
        let client = TestClient()
        XCTAssertNoThrow(try testee.startBackgroundTask(for: client), "valid case")
        XCTAssertNoThrow(try testee.endBackgroundTask(for: client), "valid case")
    }

    func testStartBackgroundTask_alreadRuning() {
        let client = TestClient()
        XCTAssertNoThrow(try testee.startBackgroundTask(for: client), "valid case")
        XCTAssertThrowsError(try testee.startBackgroundTask(for: client),
                             "Invalid case. Another task is running for this client.") { error in
                                guard let error = error as? BackgroundTaskManager.ManagingError else {
                                    XCTFail("Wrong error type")
                                    return
                                }
                                XCTAssertEqual(error, BackgroundTaskManager.ManagingError.backgroundTaskAlreadyRunning)
        }
    }

    // MARK: - endBackgroundTask

    func testEndBackgroundTask_valid() {
        let client = TestClient()
        XCTAssertNoThrow(try testee.startBackgroundTask(for: client), "valid case")
        XCTAssertNoThrow(try testee.endBackgroundTask(for: client), "valid case")
    }

    func testEndBackgroundTask_unknownClient() {
        let client = TestClient()
        XCTAssertThrowsError(try testee.endBackgroundTask(for: client),
                             "Invalid case. Unknown client asks to end a (nonexisting) background task.") { error in
                                guard let error = error as? BackgroundTaskManager.ManagingError else {
                                    XCTFail("Wrong error type")
                                    return
                                }
                                XCTAssertEqual(error, BackgroundTaskManager.ManagingError.unknownClient)
        }
    }
}

// MARK: - HELPER

extension BackgroundTaskManagerTest {

    /// Empty class to act as cllient for BackgroundTaskManager
    class TestClient: Hashable {
        private let uuid = UUID().uuidString

        static func == (lhs: BackgroundTaskManagerTest.TestClient,
                        rhs: BackgroundTaskManagerTest.TestClient) -> Bool {
            return lhs.uuid == rhs.uuid
        }

        func hash(into hasher: inout Hasher) {
            uuid.hash(into: &hasher)
        }
    }
}

