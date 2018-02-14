//
//  FolderType+IMAPTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class FolderType_IMAPTest: XCTestCase {
    let allFolderTypes = [FolderType.all,
                          FolderType.archive,
                          FolderType.drafts,
                          FolderType.flagged,
                          FolderType.inbox,
                          FolderType.normal,
                          FolderType.sent,
                          FolderType.spam,
                          FolderType.trash]
    let virtualMailboxes = [FolderType.all, FolderType.flagged]

    // MARK: - isVirtualMailbox

    func testCorrectIsVirtualMailbox() {
        for testee in allFolderTypes {
            if virtualMailboxes.contains(testee) {
                XCTAssertTrue(testee.isMostLikelyVirtualMailbox)
            } else {
                XCTAssertFalse(testee.isMostLikelyVirtualMailbox)
            }
        }
    }
}
