//
//  ComposeViewModelSectionTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 15.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class ComposeViewModelSectionTest: CoreDataDrivenTestBase {
    var state: ComposeViewModel.ComposeViewModelState?

    override func setUp() {
        super.setUp()
        state = simpleState()
    }

    override func tearDown() {
        state = nil
        super.tearDown()
    }

   /*
     for type in ComposeViewModel.Section.SectionType.allCases {
     if let section = ComposeViewModel.Section(type: type,
     for: state,
     cellVmDelegate: self) {
     newSections.append(section)
     }
     }
     */

    //case recipients, wrapped, account, subject, body, attachments

    func test_recipients_bccWrapped() {
        let to = 1
        assert(forSectionType: .recipients,
               expectedRowType: RecipientCellViewModel.self,
               expectedNumRows: to)
    }

    // MARK: - Helper

    private func assert(forSectionType sectionType: ComposeViewModel.Section.SectionType,
                        expectedRowType: AnyClass,
                        expectedNumRows: Int) {
        guard let state = state else {
            XCTFail("No State")
            return
        }
        let createe = ComposeViewModel.Section(type: sectionType,
                                               for: state,
                                               cellVmDelegate: nil)
        if expectedNumRows == 0 {
            XCTAssertNil(createe)
            return
        }
        guard let testee = createe else {
            XCTFail("Section is expected non-empty (expectedNumRows != 0)")
            return
        }
        XCTAssertEqual(testee.rows.count, expectedNumRows)
        for row in testee.rows {
            XCTAssertTrue(type(of:row) == expectedRowType, "row is correct type")
        }
    }

    private func simpleState(toRecipients: [Identity] = [],
                             ccRecipients: [Identity] = [],
                             bccRecipients: [Identity] = [],
                             isWapped: Bool = true) -> ComposeViewModel.ComposeViewModelState {
        let drafts = Folder(name: "Inbox", parent: nil, account: account, folderType: .drafts)
        drafts.save()
        let msg = Message(uuid: UUID().uuidString, parentFolder: drafts)
        msg.from = account.user
        msg.to = toRecipients
        msg.cc = ccRecipients
        msg.bcc = bccRecipients
        msg.shortMessage = "shortMessage"
        msg.longMessage = "longMessage"
        msg.longMessageFormatted = "longMessageFormatted"
        msg.attachments = [Attachment(data: Data(),
                                      mimeType: "image/jpg",
                                      contentDisposition: .attachment)]
        msg.attachments.append(Attachment(data: Data(),
                                          mimeType: "image/jpg",
                                          contentDisposition: .inline))
        msg.save()
        let initData = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                                 orForOriginalMessage: msg,
                                                 composeMode: .normal)
        let createe = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        if !isWapped {
            createe.setBccUnwrapped()
        }
        return createe
    }

}
