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
    func test_recipients() {
        let state = simpleState()
        let testee = ComposeViewModel.Section(type: .recipients, for: state, cellVmDelegate: nil)
    }
    // MARK: - Helper

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
