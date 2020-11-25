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
import MessageModelTests

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

    func testNumberOfRowsOfMessageWithTwoAttachments() {
        setupVMWithMessageWith(numberOfAttachments: 2)
        let types: [EmailRowType] = [.sender, .subject, .body, .attachment, .attachment]
        vm.retrieveAttachments()
        XCTAssert(vm.numberOfRows == types.count)
    }

    func testSubscriptRowOfMessageWithTwoAttachments() {
        setupVMWithMessageWith(numberOfAttachments: 2)
        /// We expect to see the rows in the following order:
        /// Sender, subject, body, attachments.
        XCTAssert(vm[0].type == .sender)
        XCTAssert(vm[1].type == .subject)
        XCTAssert(vm[2].type == .body)
        XCTAssert(vm[3].type == .attachment)
        XCTAssert(vm[4].type == .attachment)
    }

    // MARK: - VM

    func testBody() {
        setupVMWithMessageWith(numberOfAttachments: 1)
        vm.body { (result) in
            XCTAssert(result.string == "Long")
        }
    }

    func testCellIdentifier() {
        setupVMWithMessageWith(numberOfAttachments: 1)
        /// We expect to see the rows in the following order:
        /// Sender, subject, body, attachments.
        /// So we expect to get the corresponding cell identifier for those index path position.
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
        setupVMWithMessageWithoutAttachment()
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

    // MARK: - handleDidTapAttachment

    func testShowQuickLookOfAttachment() {
        let showQuickLookOfAttachmentExpectation = XCTestExpectation(description: "showQuickLookOfAttachment was called")
        let delegate = MockEmailViewModelDelegate(showQuickLookOfAttachmentExpectation: showQuickLookOfAttachmentExpectation)
        let numberOfAttachments = 1
        setupVMWithMessageWith(numberOfAttachments: numberOfAttachments, delegate: delegate)
        let rowOfFirstAttachment = vm.numberOfRows - numberOfAttachments
        let indexPathOfTheAttachment = IndexPath(row: rowOfFirstAttachment, section: 0)
        vm.handleDidTapAttachment(at: indexPathOfTheAttachment)
        wait(for: [showQuickLookOfAttachmentExpectation], timeout: TestUtil.waitTime)
    }

    func testShowClientCertificateImport() throws {
        let showClientCertificateImportExpectation = XCTestExpectation(description: "showClientCertificateImport")
        let delegate = MockEmailViewModelDelegate(showClientCertificateImportExpectation:showClientCertificateImportExpectation)
        let numberOfAttachments = 1
        setupVMWithMessageWithCertificateAttachment(delegate: delegate)
        let rowOfFirstAttachment = vm.numberOfRows - numberOfAttachments
        let indexPathOfTheAttachment = IndexPath(row: rowOfFirstAttachment, section: 0)
        vm.handleDidTapAttachment(at: indexPathOfTheAttachment)
        wait(for: [showClientCertificateImportExpectation], timeout: TestUtil.waitTime)
    }

    func testShowDocumentsEditor() {
        let showDocumentsEditorExpectation = XCTestExpectation(description: "showDocumentEditor was called")
        let delegate = MockEmailViewModelDelegate(showDocumentsEditorExpectation:showDocumentsEditorExpectation)
        let numberOfAttachments = 1
        let fileName = "random"
        let fileExtension = "docx"
        let fileData = loadFile(withName: fileName, withExtension: fileExtension)

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
        let attachment = Attachment(data: fileData, mimeType: "docx", fileName: "random", contentDisposition: .attachment)
        message.replaceAttachments(with: [attachment])
        Session.main.commit()
        vm = EmailViewModel(message: message, delegate: delegate)

        let rowOfFirstAttachment = vm.numberOfRows - numberOfAttachments
        let indexPathOfTheAttachment = IndexPath(row: rowOfFirstAttachment, section: 0)
        vm.handleDidTapAttachment(at: indexPathOfTheAttachment)
        wait(for: [showDocumentsEditorExpectation], timeout: TestUtil.waitTime)
    }
}

//MARK: - Setup VM

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

    private func setupVMWithMessageWith(numberOfAttachments attachments : Int, delegate: EmailViewModelDelegate = MockEmailViewModelDelegate()) {
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
            Session.main.commit()
            vm = EmailViewModel(message: message, delegate: delegate)
        }
    }

    private func setupVMWithMessageWithCertificateAttachment(delegate: EmailViewModelDelegate) {
        if vm == nil {
            let fileName = "test01_internal_cert"
            let fileExtension = "pEp12"
            let fileData = loadFile(withName: fileName, withExtension: fileExtension)

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
            let attachment = Attachment(data: fileData, mimeType: fileExtension, fileName: fileName + ".pEp12", contentDisposition: .attachment)
            message.replaceAttachments(with: [attachment])
            Session.main.commit()
            vm = EmailViewModel(message: message, delegate: delegate)
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
        self.showClientCertificateImportExpectation = showClientCertificateImportExpectation
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

extension XCTestCase {

    /// Loads the file and retrive its data.
    /// - Parameters:
    ///   - name: The name of the file
    ///   - fileExtension: The file extension
    /// - Returns: The data if doesnt fail. In case it does, check the target of the file.
    func loadFile(withName name: String, withExtension fileExtension: String) -> Data? {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: name, withExtension: fileExtension) else {
            Log.shared.error("File not found.")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            Log.shared.error("Data not found.")
            return nil
        }
        return data
    }
}
