//
//  MockBackgrounder.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import Foundation

@testable import pEpForiOS

class MockBackgrounder: BackgroundTaskProtocol {
    let expBackgrounded: XCTestExpectation?
    var currentTaskID = 1
    var taskIDs = Set<BackgroundTaskID>()

    init(expBackgrounded: XCTestExpectation? = nil) {
        self.expBackgrounded = expBackgrounded
    }

    func beginBackgroundTask(taskName: String?,
                             expirationHandler: (() -> Void)?) -> BackgroundTaskID {
        let taskID = currentTaskID
        taskIDs.insert(taskID)
        currentTaskID += 1
        return taskID
    }

    func endBackgroundTask(_ taskID: BackgroundTaskID?) {
        if let theID = taskID, taskIDs.contains(theID) {
            expBackgrounded?.fulfill()
        } else {
            XCTFail()
        }
    }
}
