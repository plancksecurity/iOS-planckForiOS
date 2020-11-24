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

class EmailViewModelTest: XCTestCase {
    private var vm : EmailViewModel!

    override func setUp() {
        super.setUp()
        setupVMWithMessageWithoutAttachment()
    }

    func testInitialization()  {
        XCTAssertNotNil(vm)
    }

    // MARK: - Rows

    func testNumberOfRows() {
        /// As the message doesn't have attachments, it has only from, subject and body.
        let types : [EmailRowType] = [.sender, .subject, .body]
        XCTAssert(vm.numberOfRows == types.count)
    }

    func testNumberOfRowsOfMessageWithOneAttachment() {
        vm = nil
        setupVMWithMessageWith(numberOfAttachments: 1)
        /// As the message has an attachment, it has from, subject and body and attachments.
        let types : [EmailRowType] = [.sender, .subject, .body, .attachment]
        XCTAssert(vm.numberOfRows == types.count)
    }

    func testNumberOfRowsOfMessageWithTwoAttachments() {
        vm = nil
        setupVMWithMessageWith(numberOfAttachments: 2)
        /// As the message has an attachment, it has from, subject and body and attachments.
        let types : [EmailRowType] = [.sender, .subject, .body, .attachment]
        XCTAssert(vm.numberOfRows == types.count)
    }

    func testSubscriptRowOfMessageWithTwoAttachments() {
        vm = nil
        setupVMWithMessageWith(numberOfAttachments: 2)
        XCTAssert(vm[0].type == .sender)
        XCTAssert(vm[1].type == .subject)
        XCTAssert(vm[2].type == .body)
        XCTAssert(vm[3].type == .attachment)
    }

    func testBody() {
        vm = nil
        setupVMWithMessageWith(numberOfAttachments: 1)
        vm.body { (result) in
            XCTAssert(result.string == "Long")
        }
    }

    // MARK: - Delegate

    func testShowLoadingView() {
        let showLoadingViewExpectation = XCTestExpectation(description: "showLoadingView was called")
        let delegate = MockEmailViewModelDelegate(showLoadingViewExpectation: showLoadingViewExpectation)
        vm.delegate = delegate
        vm.delegate?.showLoadingView()
    }


    func testHideLoadingView() {
        let hideLoadingViewExpectation = XCTestExpectation(description: "hideLoadingView was called")
        let delegate = MockEmailViewModelDelegate(hideLoadingViewExpectation: hideLoadingViewExpectation)
        vm.delegate = delegate
        vm.delegate?.showLoadingView()
    }

    func testShowQuickLookOfAttachment() {
        let showQuickLookOfAttachmentExpectation = XCTestExpectation(description: "showQuickLookOfAttachment was called")
        let delegate = MockEmailViewModelDelegate(showQuickLookOfAttachmentExpectation: showQuickLookOfAttachmentExpectation)
        vm.delegate = delegate
        if let url = URL(string: "http://www.google.com") {
            let item = url as QLPreviewItem
            vm.delegate?.showQuickLookOfAttachment(qlItem: item)
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
    }

    func testShowClientCertificateImport() {
        let showClientCertificateImportExpectation = XCTestExpectation(description: "showClientCertificateImport was called")
        let delegate = MockEmailViewModelDelegate(showClientCertificateImportExpectation: showClientCertificateImportExpectation)
        vm.delegate = delegate
        if let url = URL(string: "http://www.google.com") {
            let clientCertificate = ClientCertificateImportViewModel(certificateUrl: url)
            vm.delegate?.showClientCertificateImport(viewModel: clientCertificate)
        }
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
                                                 attachments: 1,
                                                 dispositionType: .attachment,
                                                 uid: 0)
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
