//
//  TestUtils.swift
//  pEpIOSToolboxTests
//
//  Created by Alejandro Gelos on 19/03/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import Foundation

import PEPObjCAdapter

class TestUtils {
    /**
     The maximum time for tests that don't consume any remote service.
     */
    static let waitTimeLocal: TimeInterval = 3

    /**
     The maximum time most intergationtests are allowed to run.
     */
    static let waitTime: TimeInterval = 30

    /// Delete pEp working data.
    public static func pEpClean() -> Bool {
        PEPSession.cleanup()

        let homeString = PEPObjCAdapter.perUserDirectoryString()
        let homeUrl = URL(fileURLWithPath: homeString, isDirectory: true)

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: homeString) {
            // Might happen if engine was never used.
            return true
        }

        guard let enumerator = fileManager.enumerator(atPath: homeString) else {
            // Since we already know the directory exists, not getting back
            // an enumerator is an error.
            return false
        }

        var success = true
        for path in enumerator {
            if let pathString = path as? String {
                let fileUrl = URL(fileURLWithPath: pathString, relativeTo: homeUrl)
                do {
                    try fileManager.removeItem(at: fileUrl)
                } catch {
                    success = false
                }
            } else {
                success = false
            }
        }

        return success
    }
}
