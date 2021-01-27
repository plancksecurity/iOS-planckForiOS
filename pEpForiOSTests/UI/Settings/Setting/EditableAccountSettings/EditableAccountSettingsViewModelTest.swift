//
//  EditableAccountSettingsViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 7/12/20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
import pEpIOSToolbox
@testable import pEpForiOS
@testable import MessageModel

class EditableAccountSettingsViewModelTest: AccountDrivenTestBase {

    var viewModel: EditableAccountSettingsViewModel?

    override func setUp() {
        super.setUp()
        let mockViewController = MockEditableViewController()
        viewModel = EditableAccountSettingsViewModel(account: account, delegate: mockViewController)
    }

    func testViewModelNotNil() {
        XCTAssertNotNil(viewModel)
    }

    //MARK: - Sections & Rows

    func testThereAreASectionForEachType() {
        guard let types1 = viewModel?.sections.map({$0.type}) else {
            XCTFail()
            return
        }
        let types2 = AccountSettingsViewModel.SectionType.allCases
        for (e1, e2) in zip(types1, types2) {
            if e1 != e2 {
                XCTFail()
            }
        }
    }

    func testRowsInAccountSecction() {
        evaluateRowsInAccountSection(isOauth: false)
    }

    func testRowsInImapSection() {
        let imapSectionIndex = 1
        evaluateRowsInServerSection(sectionIndex: imapSectionIndex)
    }

    func testRowsInSMTPSection() {
        let smtpSectionIndex = 2
        evaluateRowsInServerSection(sectionIndex: smtpSectionIndex)
    }

    func testRowsInAccountSecctionForOAuthAccount() {
        account.imapServer?.authMethod = AuthMethod.saslXoauth2.rawValue
        account.imapServer?.credentials.password = getPayload()
        viewModel = EditableAccountSettingsViewModel(account: account)
        evaluateRowsInAccountSection(isOauth: true)
    }

    //MARK: - Edit Account

    func testHandleRowDidChange() {
        testChangeValue(sectionType: .account, rowType: .name)
        testChangeValue(sectionType: .account, rowType: .email)
        testChangeValue(sectionType: .account, rowType: .password)

        testChangeValue(sectionType: .smtp, rowType: .server)
        testChangeValue(sectionType: .smtp, rowType: .port)
        testChangeValue(sectionType: .smtp, rowType: .tranportSecurity)
        testChangeValue(sectionType: .smtp, rowType: .username)

        testChangeValue(sectionType: .imap, rowType: .server)
        testChangeValue(sectionType: .imap, rowType: .port)
        testChangeValue(sectionType: .imap, rowType: .tranportSecurity)
        testChangeValue(sectionType: .imap, rowType: .username)
    }

    func testHandleSaveButtonPressed() {
        let setLoadingViewExpectation = XCTestExpectation(description: "setLoadingViewExpectation was called")
        let dismissYourselfExpectation = XCTestExpectation(description: "dismissYourselfExpectation was called")
        let didChangeExpectation = XCTestExpectation(description: "didChangeExpectation was called")

        let mockViewController = MockEditableViewController(setLoadingViewExpectation: setLoadingViewExpectation,
                                                            dismissYourselfExpectation: dismissYourselfExpectation)
        viewModel = EditableAccountSettingsViewModel(account: account, delegate: mockViewController)
        let accountSettingsDelegate = MockAccountSettingsViewController(didChangeExpectation: didChangeExpectation)
        viewModel?.changeDelegate = accountSettingsDelegate
        viewModel?.handleSaveButtonPressed()
    }

    func testClientCertificateRowPressed() {
        let cdClientCertificate = CdClientCertificate(context: account.moc)
        let clientCertificate = ClientCertificate(cdObject: cdClientCertificate, context: account.moc)
        let showEditCertificateExpectation = expectation(description: "showEditCertificateExpectation was called")
        let mockViewController = MockEditableViewController(showEditCertificateExpectation: showEditCertificateExpectation)
        account.imapServer?.credentials.clientCertificate = clientCertificate
        viewModel = EditableAccountSettingsViewModel(account: account, delegate: mockViewController)
        mockViewController.showEditCertificate()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testClientCertificateManagementViewModel() {
        let clientCertificateManagementViewModel = viewModel?.clientCertificateManagementViewModel()
        XCTAssertEqual(clientCertificateManagementViewModel?.accountToUpdate, account)
    }

    func testTransportSecurityIndexWithInvalidText() {
        let expectedInvalidReturnValue = -1
        let invalidIndex = viewModel?.transportSecurityIndex(for: "Invalid Transport Security Text")
        XCTAssertEqual(invalidIndex, expectedInvalidReturnValue)
    }

    func testTransportSecurityIndexWithValidText() {
        Server.Transport.allCases.forEach { (transport) in
            let index = viewModel?.transportSecurityIndex(for: transport.asString())
            XCTAssertEqual(index, Server.Transport.allCases[index!].index)
        }
    }

    func testTransportSecurityIndex() {
        Server.Transport.allCases.forEach { (transport) in
            let index = viewModel?.transportSecurityIndex(for: transport.asString())
            let option = viewModel?.transportSecurityOption(atIndex: index!)
            XCTAssertEqual(transport.asString(), option)
        }
    }
}

//MARK:- Helpers

extension EditableAccountSettingsViewModelTest {

    private func evaluateRowsInServerSection(sectionIndex: Int) {
        let serverRowTypes: [AccountSettingsViewModel.RowType] = [.server, .port, .tranportSecurity, .username]
        guard let rowTypesForServerSection = viewModel?.sections[sectionIndex].rows.map({$0.type}) else {
            XCTFail()
            return
        }
        for (e1, e2) in zip(rowTypesForServerSection, serverRowTypes) {
            if e1 != e2 {
                XCTFail()
            }
        }
    }

    private func evaluateRowsInAccountSection(isOauth: Bool) {
        let accountSectionNumer = 0
        var accountRowTypes: [AccountSettingsViewModel.RowType] = [.name, .email]
        if !isOauth {
            accountRowTypes.append(.password)
        }

        guard let rowTypesForAccountSection = viewModel?.sections[accountSectionNumer].rows.map({$0.type}) else {
            XCTFail()
            return
        }
        for (e1, e2) in zip(rowTypesForAccountSection, accountRowTypes) {
            if e1 != e2 {
                XCTFail()
            }
        }
    }

    private func getPayload() -> String {
        /// This is a valid payload for OAuth, taken from a Test Account.
        return "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGvEDALDBMUIDNKVlxdY2doJGxtbnJzdHV2d3h+goaHiImPkJGWmqWmp6isr7C9vsLGys5VJG51bGzTDQ4PEBESViRjbGFzc1prZXlDaGFpbklEWWF1dGhTdGF0ZYAvgAKAA18QJEI2QzNFMzZCLTc3MDctNEE3Ny1CMEU2LTA4QjYyNzQ5MEI4MdYVFhcNGBkaGxwdHh9fEBFsYXN0VG9rZW5SZXNwb25zZVVzY29wZVxyZWZyZXNoVG9rZW5fEBlsYXN0QXV0aG9yaXphdGlvblJlc3BvbnNlXxARbmVlZHNUb2tlblJlZnJlc2iAIoAkgCOALoAECNohIg0jJBYlJicoKSorKS0uLykxKVpleHBpcmVzX2luXxAUYWRkaXRpb25hbFBhcmFtZXRlcnNadG9rZW5fdHlwZVRjb2RlV3JlcXVlc3RYaWRfdG9rZW5Vc3RhdGVcYWNjZXNzX3Rva2VugACAHYAhgACAGoAbgAWAAIAcgADdJyI0NTY3OBYNOTo7PD0+P0BBQkNERUZHSCldcmVzcG9uc2VfdHlwZVVub25jZV8QFWNvZGVfY2hhbGxlbmdlX21ldGhvZF1jb2RlX3ZlcmlmaWVyXWNvbmZpZ3VyYXRpb25eY29kZV9jaGFsbGVuZ2VccmVkaXJlY3RfdXJpWWNsaWVudF9pZF1jbGllbnRfc2VjcmV0gBKAF4ANgBOAFoAUgAaAD4AZgBWAEIAOgADWS0xNDU5PUCkpUylVXXRva2VuRW5kcG9pbnRfEBRyZWdpc3RyYXRpb25FbmRwb2ludF8QEWRpc2NvdmVyeURvY3VtZW50Vmlzc3Vlcl8QFWF1dGhvcml6YXRpb25FbmRwb2ludIAKgACAAIAMgACAB9NXDVgpWltXTlMuYmFzZVtOUy5yZWxhdGl2ZYAAgAmACF8QLGh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi92Mi9hdXRo0l5fYGFaJGNsYXNzbmFtZVgkY2xhc3Nlc1VOU1VSTKJgYlhOU09iamVjdNNXDVgpWmaAAIAJgAtfECpodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9vYXV0aDIvdjQvdG9rZW7SXl9pal8QF09JRFNlcnZpY2VDb25maWd1cmF0aW9uomtiXxAXT0lEU2VydmljZUNvbmZpZ3VyYXRpb25fEEg2OTAyMTQyNzgxMjctOG5ubjF0MjB1NWtvbGdqNmloMDNsdTViazA2cDc3dDQuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb21fEBhodHRwczovL21haWwuZ29vZ2xlLmNvbS/TVw1YKVpxgACACYARXxBnY29tLmdvb2dsZXVzZXJjb250ZW50LmFwcHMuNjkwMjE0Mjc4MTI3LThubm4xdDIwdTVrb2xnajZpaDAzbHU1YmswNnA3N3Q0Oi9vYXV0aDI/dG9rZW49NjI5MDQwMjgyLjA0Njc4MV8QK0pqRHhDTnUtcjhheHplZFRWMm52algwbU1lalZZeHdVME5oV0hsYXI3TkFfECtrc19jOVUzNWxFMHd3Mmx6ZzlBRGRVdnJzY1RreDRSRldFdGw2YjQyNFdZXxArUEJuN0V4anJadkJ6LUpfajh0UG9CWXBnRjBjRTJ2b0dSRExZVlktZEw4d18QK1dvblQ1eFhfLTVfbkRaSVRIRWhydnJ2bmdZQnFIUGFWcGJKZGZtZU1aUmdUUzI1NtN5eg17fH1XTlMua2V5c1pOUy5vYmplY3RzoKCAGNJeX3+AXE5TRGljdGlvbmFyeaKBYlxOU0RpY3Rpb25hcnnSXl+DhF8QF09JREF1dGhvcml6YXRpb25SZXF1ZXN0ooViXxAXT0lEQXV0aG9yaXphdGlvblJlcXVlc3RfEEk0LzBBWTBlLWc3OVRkbmdteThkRnRUYnI2UEhsWjdZWFlaQzBEZGhVaEpyWi1zT0JnQVRxZnlLQU9CVzVDQU50cG55NWlXTHBBXxAYaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vXxArSmpEeENOdS1yOGF4emVkVFYybnZqWDBtTWVqVll4d1UwTmhXSGxhcjdOQdN5eg2KjI6hi4AeoY2AH4AgVXRva2VuXxAQNjI5MDQwMjgyLjA0Njc4MdJeX5KTXxATTlNNdXRhYmxlRGljdGlvbmFyeaOUlWJfEBNOU011dGFibGVEaWN0aW9uYXJ5XE5TRGljdGlvbmFyedJeX5eYXxAYT0lEQXV0aG9yaXphdGlvblJlc3BvbnNlopliXxAYT0lEQXV0aG9yaXphdGlvblJlc3BvbnNl2SINIxabJSYoIZydnhscoSmjpF1yZWZyZXNoX3Rva2VugCyALYAlgCSAI4ApgACAKIAmXxBmMS8vMDN5NmpyV0FtaU5XZkNnWUlBUkFBR0FNU05nRi1MOUlyeVV3THE4dllwbXlwTklFUEJyYWMyTXpjOVpvaHZMYVdkZTNZV3ZCdzhmSFBya1N4d25iYmpoNjI0QVFnbDBuNHd3XxAYaHR0cHM6Ly9tYWlsLmdvb2dsZS5jb20vVkJlYXJlctKpDaqrV05TLnRpbWUjQcK/OfeEhX+AJ9JeX62uVk5TRGF0ZaKtYl8QsnlhMjkuYTBBZkg2U01EbTluUXZPRmJmaG1mNVdZTW80bGtCb3QwUFByYnJzdGd0NzNNZ3lGYkpYLTg2UTlWX2hqcTJpVjVpc2J2SEJCQWZOZUJEZEFXeWFnZnB1bldnNXg2cE9Dbzk5THdKNEp3OGtqU09nTm9jSzJJdWpVSzdDbWxOR3ROZWdUNE9nSmpOSjdGVVM4Qmp0QldwbklneGpiREdJOVUtM25aM0I4bWs2WHPbIg0kFjixmzo8Ozc+sy0pQ7cpRylIQlpncmFudF90eXBlgBeAK4AagACABoAqgACAEIAAgA6AFF8QEmF1dGhvcml6YXRpb25fY29kZdJeX7/AXxAPT0lEVG9rZW5SZXF1ZXN0osFiXxAPT0lEVG9rZW5SZXF1ZXN003l6DcPEjqCggCDSXl/HyF8QEE9JRFRva2VuUmVzcG9uc2WiyWJfEBBPSURUb2tlblJlc3BvbnNl0l5fy8xcT0lEQXV0aFN0YXRlos1iXE9JREF1dGhTdGF0ZdJeX8/QXxAeTWVzc2FnZU1vZGVsLk9BdXRoMkFjY2Vzc1Rva2VuotFiXxAeTWVzc2FnZU1vZGVsLk9BdXRoMkFjY2Vzc1Rva2VuAAgAEQAaACQAKQAyADcASQBMAFEAUwCGAIwAkwCaAKUArwCxALMAtQDcAOkA/QEDARABLAFAAUIBRAFGAUgBSgFLAWABawGCAY0BkgGaAaMBqQG2AbgBugG8Ab4BwAHCAcQBxgHIAcoB5QHzAfkCEQIfAi0CPAJJAlMCYQJjAmUCZwJpAmsCbQJvAnECcwJ1AncCeQJ7AogClgKtAsECyALgAuIC5ALmAugC6gLsAvMC+wMHAwkDCwMNAzwDQQNMA1UDWwNeA2cDbgNwA3IDdAOhA6YDwAPDA90EKARDBEoETAROBFAEugToBRYFRAVyBXcFfgWGBZEFkgWTBZUFmgWnBaoFtwW8BdYF2QXzBj8GWgaIBo8GkQaTBpUGlwaZBp8Gsga3Bs0G0QbnBvQG+QcUBxcHMgdFB1MHVQdXB1kHWwddB18HYQdjB2UHzgfpB/AH9Qf9CAYICAgNCBQIFwjMCOMI7gjwCPII9Aj2CPgI+gj8CP4JAAkCCQQJGQkeCTAJMwlFCUwJTQlOCVAJVQloCWsJfgmDCZAJkwmgCaUJxgnJAAAAAAAAAgEAAAAAAAAA0gAAAAAAAAAAAAAAAAAACeo="
    }


    private func testChangeValue(sectionType: AccountSettingsViewModel.SectionType, rowType: AccountSettingsViewModel.RowType) {
        guard let sectionIndex = sectionType.index else {
            XCTFail()
            return
        }
        let section = viewModel?.sections[sectionIndex]
        guard let rowIndex = section?.rows.firstIndex(where: {$0.type == rowType}) else {
            XCTFail()
            return
        }
        let indexPath = IndexPath(row:rowIndex, section:sectionIndex)

        guard let originalRow = section?.rows[rowIndex] as? AccountSettingsViewModel.DisplayRow else {
            XCTFail()
            return
        }

        let newValue = "Other value!"
        viewModel?.handleRowDidChange(at: indexPath, value: newValue)
        guard let rowModified = viewModel?.sections[indexPath.section].rows[indexPath.row] as? AccountSettingsViewModel.DisplayRow else {
            XCTFail()
            return
        }
        XCTAssertTrue(rowModified.text == newValue)
        XCTAssertTrue(originalRow.text != newValue)
    }
}

class MockEditableViewController: EditableAccountSettingsDelegate {

    private var setLoadingViewExpectation: XCTestExpectation?
    private var showAlertExpectation: XCTestExpectation?
    private var dismissYourselfExpectation: XCTestExpectation?
    private var showEditCertificateExpectation: XCTestExpectation?

    init(setLoadingViewExpectation: XCTestExpectation? = nil,
         showAlertExpectation: XCTestExpectation? = nil,
         dismissYourselfExpectation: XCTestExpectation? = nil,
         showEditCertificateExpectation: XCTestExpectation? = nil) {
        self.setLoadingViewExpectation = setLoadingViewExpectation
        self.showAlertExpectation = showAlertExpectation
        self.dismissYourselfExpectation = dismissYourselfExpectation
        self.showEditCertificateExpectation = showEditCertificateExpectation
    }

    func setLoadingView(visible: Bool) {
        fulfillIfNotNil(expectation: setLoadingViewExpectation)
    }

    func showAlert(error: Error) {
        fulfillIfNotNil(expectation: showAlertExpectation)
    }

    func dismissYourself() {
        fulfillIfNotNil(expectation: dismissYourselfExpectation)
    }

    func showEditCertificate() {
        fulfillIfNotNil(expectation: showEditCertificateExpectation)
    }

    private func fulfillIfNotNil(expectation: XCTestExpectation?) {
        if expectation != nil {
            expectation?.fulfill()
        }
    }
}

class MockAccountSettingsViewController: VerifiableAccount, SettingChangeDelegate {

    private var didChangeExpectation: XCTestExpectation?

    init(didChangeExpectation: XCTestExpectation? = nil) {
        self.didChangeExpectation = didChangeExpectation
    }

    func didChange() {
        fulfillIfNotNil(expectation: didChangeExpectation)
    }

    private func fulfillIfNotNil(expectation: XCTestExpectation?) {
        if expectation != nil {
            expectation?.fulfill()
        }
    }

    override func save(completion: @escaping (Result<Void, Error>) -> ()) {
        super.save { [weak self] success in
            self?.verifiableAccountDelegate?.didEndVerification(result: success)
            completion(success)
        }
    }
}
