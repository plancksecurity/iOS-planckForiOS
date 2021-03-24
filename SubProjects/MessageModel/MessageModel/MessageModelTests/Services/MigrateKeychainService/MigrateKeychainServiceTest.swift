//
//  MigrateKeychainServiceTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 22.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class MigrateKeychainServiceTest: XCTestCase {
    var keysAdded = [String:String]()
    var certificatesAdded = [String]()

    override func setUpWithError() throws {
        setupKeychainPasswords()
        setupClientCertificates()

        for i in 1...numberOfKeyPasswordPairs {
            // Expectation: All created entries exist (somewhere in the default)
            query(key: key(index: i),
                  password: password(index: i))
        }

        for i in 1...numberOfKeyPasswordPairs {
            // Expectation: No entries in the target keychain
            query(key: key(index: i),
                  password: nil,
                  accessGroup: keychainTargetGroup)
        }

        let certUtil = ClientCertificateUtil()
        XCTAssertEqual(certUtil.listExisting().count, certificatesAdded.count)

        XCTAssertEqual(numberOfCertificates(groupName: nil), certificatesAdded.count)
        XCTAssertEqual(numberOfCertificates(groupName: keychainTargetGroup), 0)
    }

    override func tearDownWithError() throws {
        removeKeychainPasswords()
        removeClientCertificates()

        for i in 1...numberOfKeyPasswordPairs {
            // Expectation: All entries deleted
            query(key: key(index: i),
                  password: nil)
        }

        let clientUtil = ClientCertificateUtil()
        XCTAssertEqual(clientUtil.listExisting().count, 0)
    }

    func testOperation() throws {
        let expFinished = expectation(description: "expFinished")

        let op = MigrateKeychainOperation(keychainGroupTarget: keychainTargetGroup)
        op.completionBlock = {
            expFinished.fulfill()
        }
        op.start()

        waitForExpectations(timeout: TestUtil.waitTime)

        verifyEndConditions()
    }

    func testService() throws {
        let expFinished = expectation(description: "expFinished")

        let service = MigrateKeychainService(keychainGroupTarget: keychainTargetGroup)
        service.finishBlock = {
            expFinished.fulfill()
        }
        service.start()
        service.finish()

        waitForExpectations(timeout: TestUtil.waitTime)

        verifyEndConditions()
    }

    // MARK: - Private Helpers

    static let defaultServerType = "Server"

    let numberOfKeyPasswordPairs = 50

    let keychainTargetGroup = "group.security.pep.test.pep4ios"

    private func key(index: Int) -> String {
        return "key_\(index)"
    }

    private func password(index: Int) -> String {
        return "password\(index)"
    }

    private func setupKeychainPasswords() {
        for i in 1...numberOfKeyPasswordPairs {
            let theKey = key(index: i)
            let thePassword = password(index: i)
            add(key: theKey, password: thePassword)
            keysAdded[theKey] = thePassword
        }
    }

    private func removeKeychainPasswords() {
        for (key, password) in keysAdded {
            remove(key: key, password: password)
        }
    }

    private func setupClientCertificates() {
        let certificateFilenames = ["Certificate_001.p12", "Certificate_002.p12", "Certificate_003.p12"]

        for certFilename in certificateFilenames {
            storeCertificate(filename: certFilename, password: "uiae")
        }

        certificatesAdded = certificateFilenames
    }

    private func removeClientCertificates() {
        let util = ClientCertificateUtil()

        let identityPairs = util.listExisting()
        for (uuidLabel, secIndentity) in identityPairs {
            let removeQuery: [CFString : Any] = [kSecAttrLabel: uuidLabel,
                                                 kSecValueRef: secIndentity]

            let removeStatus = SecItemDelete(removeQuery as CFDictionary)
            XCTAssertEqual(removeStatus, errSecSuccess)
        }
    }

    private func verifyEndConditions() {
        for i in 1...numberOfKeyPasswordPairs {
            // Expectation: All created entries exist (somewhere in the default)
            query(key: key(index: i),
                  password: password(index: i))
        }

        for i in 1...numberOfKeyPasswordPairs {
            // Expectation: All created entries exist specifically in the target
            query(key: key(index: i),
                  password: password(index: i),
                  accessGroup: keychainTargetGroup)
        }

        // Verify that all certificates now exist in the target group
        XCTAssertEqual(numberOfCertificates(groupName: nil), certificatesAdded.count)
        XCTAssertEqual(numberOfCertificates(groupName: keychainTargetGroup), certificatesAdded.count)
    }

    private func basicPasswordQuery(key: String,
                                    password: String?,
                                    serverType: String = MigrateKeychainServiceTest.defaultServerType) -> [String : Any] {
        var query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrService as String: serverType,
            kSecAttrAccount as String: key] as [String : Any]

        if let thePassword = password {
            if let passwordData = thePassword.data(using: String.Encoding.utf8) {
                query[kSecValueData as String] = passwordData
            } else {
                XCTFail()
            }
        }

        return query
    }

    private func add(key: String,
                     password: String,
                     serverType: String = MigrateKeychainServiceTest.defaultServerType) {
        let query = basicPasswordQuery(key: key, password: password, serverType: serverType)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            XCTFail()
        }
    }

    private func remove(key: String,
                        password: String,
                        serverType: String = MigrateKeychainServiceTest.defaultServerType) {
        let query = basicPasswordQuery(key: key, password: password, serverType: serverType)
        let status = SecItemDelete(query as CFDictionary)
        if status != noErr {
            XCTFail()
        }
    }

    /// - Note: A `password == nil` means that this query should yield an element not found.
    private func query(key: String,
                       password: String?,
                       accessGroup: String? = nil,
                       serverType: String = MigrateKeychainServiceTest.defaultServerType) {
        var query = basicPasswordQuery(key: key, password: password, serverType: serverType)

        query[kSecMatchCaseInsensitive as String] = kCFBooleanTrue as Any
        query[kSecReturnData as String] = kCFBooleanTrue as Any

        if let theGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = theGroup
        }

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if let thePassword = password {
            if status != noErr {
                // errSecItemNotFound -25300
                XCTFail("Could not copy \(key) from \(accessGroup ?? "nil"): \(status)")
                return
            }

            guard let r = result as? Data else {
                XCTFail()
                return
            }
            let str = String(data: r, encoding: String.Encoding.utf8)
            guard let theStr = str else {
                XCTFail()
                return
            }
            XCTAssertEqual(str, thePassword, "key \(key) has \(theStr) stored, not the expected \(thePassword)")
        } else {
            XCTAssertEqual(status, errSecItemNotFound)
        }
    }

    private func storeCertificate(filename: String, password: String) {
        XCTAssertTrue(ClientCertificatesTestUtil.storeCertificate(filename: filename,
                                                                  password: password))
    }

    func numberOfCertificates(groupName: String?) -> Int {
        var query: [CFString : Any] = [kSecClass: kSecClassIdentity,
                                       kSecMatchLimit: kSecMatchLimitAll,
                                       kSecReturnRef: true,
                                       kSecReturnAttributes: true]

        if let theGroupName = groupName {
            query[kSecAttrAccessGroup] = theGroupName
        }

        var resultRef: CFTypeRef? = nil
        let identityStatus = SecItemCopyMatching(query as CFDictionary, &resultRef)

        if identityStatus == errSecItemNotFound {
            return 0
        }

        guard identityStatus == errSecSuccess else {
            XCTFail()
            return -1
        }

        guard let theResult = resultRef else {
            XCTFail()
            return -1
        }

        guard CFGetTypeID(theResult) == CFArrayGetTypeID() else {
            XCTFail()
            return -1
        }

        let resultArray = theResult as! NSArray
        return resultArray.count
    }
}
