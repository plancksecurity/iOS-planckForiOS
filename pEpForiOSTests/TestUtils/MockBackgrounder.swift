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
import MessageModel

class MockBackgrounder: BackgroundTaskProtocol {
    let expBackgroundTaskFinished: XCTestExpectation?
    var currentTaskID = 1
    var taskIDs = Set<BackgroundTaskID>()
    var totalNumberOfBackgroundTasksStarted = 0
    var totalNumberOfBackgroundTasksFinished = 0
    var taskNames = [Int: String]()

    var numberOfBackgroundTasksOutstanding: Int {
        return taskIDs.count
    }

    init(expBackgroundTaskFinishedAtLeastOnce: XCTestExpectation? = nil) {
        self.expBackgroundTaskFinished = expBackgroundTaskFinishedAtLeastOnce
    }

    func beginBackgroundTask(taskName: String?,
                             expirationHandler: (() -> Void)?) -> BackgroundTaskID {
        totalNumberOfBackgroundTasksStarted += 1
        let taskID = currentTaskID
        print("\(#function): \(taskID) task \(taskName ?? "unknown")")
        taskNames[taskID] = taskName
        taskIDs.insert(taskID)
        currentTaskID += 1
        return taskID
    }

    func endBackgroundTask(_ taskID: BackgroundTaskID?) {
        if let theID = taskID, taskIDs.contains(theID) {
            let taskName = taskNames[theID]
            print("\(#function): \(theID) task \(taskName ?? "unknown")")
            totalNumberOfBackgroundTasksFinished += 1
            taskIDs.remove(theID)
            expBackgroundTaskFinished?.fulfill()
        } else {
            XCTFail()
        }
    }
}
