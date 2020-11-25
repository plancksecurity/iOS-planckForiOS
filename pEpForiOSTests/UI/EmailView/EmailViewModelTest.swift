//
//  EmailViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 12/11/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
import QuickLook
@testable import pEpForiOS
@testable import MessageModel
import pEpIOSToolbox

class EmailViewModelTest: XCTestCase {
    private var vm : EmailViewModel!

    func testInitialization()  {
        setupVMWithMessageWithoutAttachment()
        XCTAssertNotNil(vm)
    }

    // MARK: - Rows

    func testNumberOfRows() {
        setupVMWithMessageWithoutAttachment()
        /// As the message doesn't have attachments, it has only from, subject and body.
        let types : [EmailRowType] = [.sender, .subject, .body]
        XCTAssert(vm.numberOfRows == types.count)
    }

    func testNumberOfRowsOfMessageWithOneAttachment() {
        setupVMWithMessageWith(numberOfAttachments: 1)
        let types : [EmailRowType] = [.sender, .subject, .body, .attachment]
        XCTAssert(vm.numberOfRows == types.count)
    }

    // xxxx
    func testNumberOfRowsOfMessageWithTwoAttachments() {
        setupVMWithMessageWith(numberOfAttachments: 2)
        let types: [EmailRowType] = [.sender, .subject, .body, .attachment, .attachment]
        vm.retrieveAttachments()
        XCTAssert(vm.numberOfRows == types.count)
    }

    // xxxx
    func testSubscriptRowOfMessageWithTwoAttachments() {
        setupVMWithMessageWith(numberOfAttachments: 2)
        XCTAssert(vm[0].type == .sender)
        XCTAssert(vm[1].type == .subject)
        XCTAssert(vm[2].type == .body)
        XCTAssert(vm[3].type == .attachment)
        XCTAssert(vm[4].type == .attachment)
    }

    func testBody() {
        setupVMWithMessageWith(numberOfAttachments: 1)
        vm.body { (result) in
            XCTAssert(result.string == "Long")
        }
    }

    func testCellIdentifier() {
        setupVMWithMessageWith(numberOfAttachments: 1)
        XCTAssertEqual("senderCell", vm.cellIdentifier(for: IndexPath(row: 0, section: 0)))
        XCTAssertEqual("senderSubjectCell", vm.cellIdentifier(for: IndexPath(row: 1, section: 0)))
        XCTAssertEqual("senderBodyCell", vm.cellIdentifier(for: IndexPath(row: 2, section: 0)))
        XCTAssertEqual("attachmentsCell", vm.cellIdentifier(for: IndexPath(row: 3, section: 0)))
    }

    func testRetrieveAttachments() {
        setupVMWithMessageWith(numberOfAttachments: 4)
        let didSetAttachmentsExpectation = XCTestExpectation(description: "didSetAttachmentsExpectation")
        let delegate = MockEmailViewModelDelegate(didSetAttachmentsExpectation: didSetAttachmentsExpectation)
        vm.delegate = delegate
        vm.retrieveAttachments()
        wait(for: [didSetAttachmentsExpectation], timeout: TestUtil.waitTime)
    }

    // MARK: - Delegate

    func testShowLoadingView() {
        let showLoadingViewExpectation = XCTestExpectation(description: "showLoadingView was called")
        let delegate = MockEmailViewModelDelegate(showLoadingViewExpectation: showLoadingViewExpectation)
        vm.delegate = delegate
        vm.delegate?.showLoadingView()
        wait(for: [showLoadingViewExpectation], timeout: TestUtil.waitTime)
    }

    func testHideLoadingView() {
        setupVMWithMessageWithoutAttachment()
        let hideLoadingViewExpectation = XCTestExpectation(description: "hideLoadingView was called")
        let delegate = MockEmailViewModelDelegate(hideLoadingViewExpectation: hideLoadingViewExpectation)
        vm.delegate = delegate
        vm.delegate?.hideLoadingView()
        wait(for: [hideLoadingViewExpectation], timeout: TestUtil.waitTime)
    }

    func testShowQuickLookOfAttachment() {
        let showQuickLookOfAttachmentExpectation = XCTestExpectation(description: "showQuickLookOfAttachment was called")
        let delegate = MockEmailViewModelDelegate(showQuickLookOfAttachmentExpectation: showQuickLookOfAttachmentExpectation)
        vm.delegate = delegate
        if let url = URL(string: "http://www.google.com") {
            let item = url as QLPreviewItem
            vm.delegate?.showQuickLookOfAttachment(qlItem: item)
            wait(for: [showQuickLookOfAttachmentExpectation], timeout: TestUtil.waitTime)
        }
    }

    func testShowDocumentsEditor() {
        let showDocumentsEditorExpectation = XCTestExpectation(description: "showDocumentsEditor was called")
        let delegate = MockEmailViewModelDelegate(showDocumentsEditorExpectation: showDocumentsEditorExpectation)
        vm.delegate = delegate
        guard let url = URL(string: "http://www.google.com") else {
            XCTFail()
            return
        }
        vm.delegate?.showDocumentsEditor(url: url)
        wait(for: [showDocumentsEditorExpectation], timeout: TestUtil.waitTime)
    }

    func testShowClientCertificateImport() throws {
        //MB:- TODO: change this to create a certificate.pEp12.
        setupVMWithMessageWithCertificateAttachment()
        let showClientCertificateImportExpectation = XCTestExpectation(description: "showClientCertificateImport")
        let delegate = MockEmailViewModelDelegate(showClientCertificateImportExpectation: showClientCertificateImportExpectation)
        vm.delegate = delegate

        let indexPathOfTheAttachment = IndexPath(row: 3, section: 0)
        vm.handleDidTapAttachment(at: indexPathOfTheAttachment)
        wait(for: [showClientCertificateImportExpectation], timeout: TestUtil.waitTime)
    }
}

extension EmailViewModelTest {
    private func setupVMWithMessageWithoutAttachment() {
        if vm == nil {
            let account = TestData().createWorkingAccount()
            let inbox = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
            let identity = Identity(address: "mail@mail.com")
            let message = TestUtil.createMessage(inFolder: inbox, from: identity, dispositionType: .attachment)
            vm = EmailViewModel(message: message, delegate: MockEmailViewModelDelegate())
        }
    }

    /// Setup EmailViewModel with the following attributes
    ///  - From
    ///  - One To
    ///  - One Attachment
    private func setupVMWithMessageWith(numberOfAttachments attachments : Int) {
        if vm == nil {
            let account = TestData().createWorkingAccount()
            let inbox = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
            let fromIdentity = Identity(address: "from@mail.com")
            let toIdentity = [Identity(address: "to@mail.com")]
            let ccsIdentity = [Identity]()
            let bcsIdentity = [Identity]()
            let message = TestUtil.createMessage(inFolder: inbox,
                                                 from: fromIdentity,
                                                 tos: toIdentity,
                                                 ccs: ccsIdentity,
                                                 bccs: bcsIdentity,
                                                 engineProccesed: false,
                                                 shortMessage: "Short",
                                                 longMessage: "Long",
                                                 longMessageFormatted: "longMessageFormatted",
                                                 dateSent: Date(),
                                                 attachments: attachments,
                                                 dispositionType: .attachment,
                                                 uid: 0)
            vm = EmailViewModel(message: message, delegate: MockEmailViewModelDelegate())
        }
    }

    private func setupVMWithMessageWithCertificateAttachment() {
        if vm == nil {
            let account = TestData().createWorkingAccount()
            let inbox = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
            let message = TestUtil.createMessageWithCertificateAttached(inFolder: inbox)
            vm = EmailViewModel(message: message, delegate: MockEmailViewModelDelegate())
        }

    }
}

class MockEmailViewModelDelegate: EmailViewModelDelegate {

    private var showQuickLookOfAttachmentExpectation: XCTestExpectation?
    private var showLoadingViewExpectation: XCTestExpectation?
    private var hideLoadingViewExpectation: XCTestExpectation?
    private var showDocumentsEditorExpectation: XCTestExpectation?
    private var showClientCertificateImportExpectation: XCTestExpectation?
    private var didSetAttachmentsExpectation: XCTestExpectation?
    private var showExternalContentExpectation: XCTestExpectation?

    init(showLoadingViewExpectation: XCTestExpectation? = nil,
         hideLoadingViewExpectation: XCTestExpectation? = nil,
        showQuickLookOfAttachmentExpectation: XCTestExpectation? = nil,
        showDocumentsEditorExpectation: XCTestExpectation? = nil,
        showClientCertificateImportExpectation: XCTestExpectation? = nil,
        didSetAttachmentsExpectation: XCTestExpectation? = nil,
        showExternalContentExpectation: XCTestExpectation? = nil) {
        self.showQuickLookOfAttachmentExpectation = showQuickLookOfAttachmentExpectation
        self.showLoadingViewExpectation = showLoadingViewExpectation
        self.hideLoadingViewExpectation = hideLoadingViewExpectation
        self.showDocumentsEditorExpectation = showDocumentsEditorExpectation
        self.didSetAttachmentsExpectation = didSetAttachmentsExpectation
        self.showExternalContentExpectation = showExternalContentExpectation
    }

    func showQuickLookOfAttachment(qlItem: QLPreviewItem) {
        fulfillIfNotNil(expectation: showQuickLookOfAttachmentExpectation)
    }
    func showDocumentsEditor(url: URL) {
        fulfillIfNotNil(expectation: showDocumentsEditorExpectation)
    }

    func showClientCertificateImport(viewModel: ClientCertificateImportViewModel) {
        fulfillIfNotNil(expectation: showClientCertificateImportExpectation)
    }

    func showLoadingView() {
        fulfillIfNotNil(expectation: showLoadingViewExpectation)
    }

    func hideLoadingView() {
        fulfillIfNotNil(expectation: hideLoadingViewExpectation)
    }

    func didSetAttachments(forRowsAt indexPaths: [IndexPath]) {
        fulfillIfNotNil(expectation: didSetAttachmentsExpectation)
    }

    func showExternalContent() {
        fulfillIfNotNil(expectation: showExternalContentExpectation)
    }


    private func fulfillIfNotNil(expectation: XCTestExpectation?) {
        if expectation != nil {
            expectation?.fulfill()
        }
    }
}

extension EmailViewModelTest {
    func createCert() {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail()
            return
        }
        let newUrl = url.appendingPathComponent("certificate", isDirectory: false).appendingPathExtension("pEp12")
        do {
            try Data(base64Encoded: "somedata")?.write(to: newUrl)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
