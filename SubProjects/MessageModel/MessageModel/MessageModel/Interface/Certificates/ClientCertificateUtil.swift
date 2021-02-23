//
//  ClientCertificateUtil.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.02.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData
import pEpIOSToolbox

public protocol ClientCertificateUtilProtocol {
    /// - Parameters:
    ///   - session: Session to work on. Defaults to main Session.
    /// - Returns: A list of all currently stored certificates.
    func listCertificates(session: Session?) -> [ClientCertificate]

    /// Stores the given data (assumed to be p12 or pfx), protected by the
    /// given password.
    /// - Note: Duplicates are ignored.
    /// - Parameters:
    ///   - p12Data: The p12/pfx blob
    ///   - password: The password that can unlock the data
    /// - Throws: `ImportError`
    func storeCertificate(p12Data: Data, password: String) throws

    /// Deletes the given `ClientCertificate`, which originates from a call to `listCertificates`.
    /// - Note:
    /// * The certificate is deleted from CoreData and from the Keychain.
    /// * Attempts to delete client certificates that don't exist are ignored.
    /// - Parameter clientCertificate: The client certificate to delete.
    /// - Throws: `DeleteError`
    func delete(clientCertificate: ClientCertificate) throws

    /// Deletes the given `ClientCertificate`, even if it's being used.
    /// *USE THIS ONLY FOR ACCOUNT DELETION*
    ///
    /// - Note:
    /// * The certificate is deleted from CoreData and from the Keychain.
    /// * Attempts to delete client certificates that don't exist are ignored.
    /// - Parameter clientCertificate: The client certificate to delete.
    func forceDelete(clientCertificate: ClientCertificate)

    /// Does the given data reperesent certificate data, importable with `SecPKCS12Import`?
    func isCertificate(p12Data: Data) -> Bool
}

// MARK: - ImportError

extension ClientCertificateUtil {

    /// Errors that can be thrown by `storeCertificate(p12Data:password:)`.
    public enum ImportError: Error {
        /// The password could not unlock the data
        case wrongPassword

        /// The p12/pfx could not be parsed
        case invalidFormat

        /// The certificate contained insufficient information, so critical elements
        /// could not be constructed.
        ///
        /// For example:
        ///  * The certificate contains neither common name nor email
        case insufficientInformation

        /// An item could not be stored into the keychain
        case keychainError
    }
}

// MARK: - DeleteError

extension ClientCertificateUtil {

    /// Errors that can be thrown by `delete(clientCertificate:)`.
    public enum DeleteError: Error {
        /// The client certificate is still in use, that is linked by some credentials
        case stillInUse
    }
}

/// Class for importing, storing and listing of client-side certificates
/// (also known as identities).
/// Can be used by the UI for importing client certificates on behalf of the user, showing
/// what client certificates are available, and deletion of certificates not needed anymore.
/// Client-side certificates are required by some servers for identifying the user, in addition
/// to or as a substitute of the conventional user-name/password combination.
public class ClientCertificateUtil {

    /// Make initializable for MM clients.
    public init() {}
}

// MARK: - ClientCertificateUtilProtocol

extension ClientCertificateUtil: ClientCertificateUtilProtocol {


    public func listCertificates(session: Session? = nil) -> [ClientCertificate] {
        let moc: NSManagedObjectContext = session?.moc ?? Session.main.moc
        let existingCdCerts = CdClientCertificate.all(in: moc) as? [CdClientCertificate] ?? []
        return existingCdCerts.map { ClientCertificate(cdObject: $0, context: moc) }
    }

    public func storeCertificate(p12Data: Data, password: String) throws {
        let p12Options: NSDictionary = [kSecImportExportPassphrase: password]
        var itemsCF: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, p12Options, &itemsCF)
        if status != .zero {
            switch status {
            case errSecDecode:
                throw ImportError.invalidFormat
            case errSecAuthFailed:
                throw ImportError.wrongPassword
            default:
                throw ImportError.invalidFormat
            }
        }

        guard let theItemsCF = itemsCF else {
            throw ImportError.invalidFormat
        }

        let moc = Stack.shared.newPrivateConcurrentContext

        for anyItem in theItemsCF as NSArray {
            guard let dictionary = anyItem as? [String:AnyObject] else {
                throw ImportError.invalidFormat
            }
            guard let (keychainUuid, label) = try storeIdentityInKeychain(item: dictionary) else {
                // ignore duplicate items that could not be located in the keychain
                continue
            }
            moc.performAndWait {
                let existing = CdClientCertificate.search(label: label,
                                                          keychainUuid: keychainUuid,
                                                          context: moc)
                if (existing == nil) {
                    let cdCclientCert = CdClientCertificate(context: moc)
                    cdCclientCert.label = label
                    cdCclientCert.keychainUuid = keychainUuid
                    cdCclientCert.importDate = Date()
                    moc.saveAndLogErrors()
                }
            }
        }
    }

    public func delete(clientCertificate: ClientCertificate) throws {
        try deleteCertificate(clientCertificate: clientCertificate)
    }

    public func forceDelete(clientCertificate: ClientCertificate) {
        do {
            try deleteCertificate(clientCertificate: clientCertificate, isForceDelete: true)
        } catch {
            Log.shared.errorAndCrash("Should not throw as it's a force delete.")
        }
    }

    private func deleteCertificate(clientCertificate: ClientCertificate, isForceDelete: Bool = false) throws {
        var errorToThrow: DeleteError? = nil
        let moc = Stack.shared.newPrivateConcurrentContext
        moc.performAndWait {
            let cdCert = clientCertificate.cdObject
            guard let label = cdCert.label else {
                Log.shared.errorAndCrash("ClientCertificate Label not found")
                return
            }
            guard let keychainUuid = cdCert.keychainUuid else {
                Log.shared.errorAndCrash("Keychain Uuid not found")
                return
            }
            if let existing = CdClientCertificate.search(label: label,
                                                         keychainUuid: keychainUuid,
                                                         context: moc) {
                // Delete only if it's not being used, or if it's a force deletion.
                if isForceDelete || !isStillInUse(clientCertificate: cdCert) {
                    moc.delete(existing)
                    moc.saveAndLogErrors()
                } else {
                    errorToThrow = DeleteError.stillInUse
                }
            }
        }
        if let error = errorToThrow {
            throw error
        }
    }

    /// Removes the identity binded to the client certificate passed by parameter.
    /// If doesn't find it does nothing.
    ///
    /// - Parameter cdCertificate: The cdCertificate to find the identity to delete.
    public func removeSecIdentityFromKeychain(of cdCertificate: CdClientCertificate) {
        if let element = listExisting().first(where: {$0.0 == cdCertificate.keychainUuid}) {
            SecItemDelete([kSecValueRef: element.1] as CFDictionary)
        }
    }

    public func isCertificate(p12Data: Data) -> Bool {
        let p12Options: NSDictionary = [:]
        var itemsCF: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, p12Options, &itemsCF)
        if status != .zero {
            switch status {
            case errSecDecode:
                return false
            case errSecAuthFailed:
                return true
            default:
                return false
            }
        }
        return false
    }
}

// MARK: - Internal, used by other ClientCertificateUtil extensions

extension ClientCertificateUtil {
    
    /// - Returns: An array of client identities (`SecIdentity`) stored in the keychain,
    /// together with their label (which in our case is used as an UUID).
    func listExisting() -> [(String, SecIdentity)] {
        var result = [(String, SecIdentity)]()

        let query: [CFString : Any] = [kSecClass: kSecClassIdentity,
                                       kSecMatchLimit: kSecMatchLimitAll,
                                       kSecReturnRef: true,
                                       kSecReturnAttributes: true]
        var resultRef: CFTypeRef? = nil
        let identityStatus = SecItemCopyMatching(query as CFDictionary, &resultRef)

        guard identityStatus == errSecSuccess else {
            return []
        }

        guard let theResult = resultRef else {
            return []
        }

        guard CFGetTypeID(theResult) == CFArrayGetTypeID() else {
            return []
        }

        let resultArray = theResult as! NSArray
        for elem in resultArray {
            guard CFGetTypeID(elem as CFTypeRef) == CFDictionaryGetTypeID() else {
                continue
            }

            let resultDictionary = elem as! [CFString:AnyObject]

            guard let secObj = resultDictionary[kSecValueRef] else {
                continue
            }

            guard let labelObj = resultDictionary[kSecAttrLabel] else {
                continue
            }

            guard CFGetTypeID(secObj) == SecIdentityGetTypeID() else {
                continue
            }

            let secIdentity = secObj as! SecIdentity

            guard CFGetTypeID(labelObj) == CFStringGetTypeID() else {
                continue
            }

            guard let uuidString = labelObj as? String else {
                continue
            }

            result.append((uuidString, secIdentity))
        }

        return result
    }
}

// MARK: - Private

extension ClientCertificateUtil {
    /// Generates a user-readable label from a common name and email addresses
    /// (e.g., from a certificate).
    /// - Parameters:
    ///   - commonName: The common name of the certificate
    ///   - emailAddresses: Email addresses attached to the certificate
    /// - Returns: A user-readable name (label) for the given data, or nil if nothing could
    ///  be constructed.
    private func userReadableName(commonName: String?, emailAddresses: [String]) -> String? {
        if let theCommonName = commonName {
            if !emailAddresses.isEmpty {
                return theCommonName + " <" + emailAddresses.joined(separator: ", ") + ">"
            } else {
                return theCommonName
            }
        } else {
            if emailAddresses.count > 1 {
                return "<" + emailAddresses.joined(separator: ", ") + ">"
            } else {
                return emailAddresses.first
            }
        }
    }

    /// - Returns: A human-readable identifier (label) for a given identity
    /// - Parameter secIdentity: The identity to return a label for
    private func label(for secIdentity: SecIdentity) -> String? {
        var certificate: SecCertificate?
        let certificateStatus = SecIdentityCopyCertificate(secIdentity, &certificate)
        guard certificateStatus == errSecSuccess else {
            return nil
        }

        guard let theCertificate = certificate else {
            return nil
        }
        var commonName: String?
        var emailAddresses = Set<String>()

        var commonNameCF: CFString?
        let commonNameStatus = SecCertificateCopyCommonName(theCertificate, &commonNameCF)
        if commonNameStatus == errSecSuccess {
            commonName = commonNameCF as String?
        }

        var emailAddressesCF: CFArray?
        let emailAddressStatus = SecCertificateCopyEmailAddresses(theCertificate, &emailAddressesCF)
        if emailAddressStatus == errSecSuccess,
           let emailObjects = emailAddressesCF as [AnyObject]? {
            for obj in emailObjects {
                if let emailStr = obj as? String {
                    emailAddresses.insert(emailStr)
                }
            }
        }

        return userReadableName(commonName: commonName, emailAddresses: Array(emailAddresses))
    }

    /// Stores the given identity dictionary into the keychain.
    /// - Parameter item: The identity dictionary to be stored
    /// - Throws: `ImportError`
    /// - Returns: A tuple consisting of identifying data and a human-readable
    ///  String for identifying the identity or nil, if the item was already in the keychain,
    ///  but could not be retrieved.
    private func storeIdentityInKeychain(item: [String: AnyObject]) throws -> (String, String)? {
        guard let identityObj = item[kSecImportItemIdentity as String] else {
            throw ImportError.insufficientInformation
        }

        // Swift cannot cast AnyObject to CF conditionally, so this guard is
        // important.
        guard CFGetTypeID(identityObj) == SecIdentityGetTypeID() else {
            throw ImportError.insufficientInformation
        }

        // See the CFGetTypeID() check above.
        let theSecIdentity = identityObj as! SecIdentity

        guard let identityLabel = label(for: theSecIdentity) else {
            throw ImportError.insufficientInformation
        }
        let uuidLabel = NSUUID().uuidString
        let addIdentityAttributes: [CFString : Any] = [kSecReturnPersistentRef: true,
                                                       kSecAttrLabel: uuidLabel,
                                                       kSecValueRef: theSecIdentity]
        var resultRef: CFTypeRef? = nil
        let identityStatus = SecItemAdd(addIdentityAttributes as CFDictionary, &resultRef);

        if identityStatus != errSecSuccess {
            if let error = identityStatus.error {
                Log.shared.error("%@", "\(error.localizedDescription)")
            }
            if identityStatus != errSecDuplicateItem {
                // Throw on all errors except duplicate items
                throw ImportError.keychainError
            } else {
                // The keychain already has an item of the same class with the same set of composite primary keys
                // https://developer.apple.com/documentation/security/errsecduplicateitem
                //
                // If the error hints at a duplicate already in the keychain,
                // try to find it.
                if let existingUuid = matchExisting(secIdentity: theSecIdentity) {
                    return (existingUuid, identityLabel)
                } else {
                    return nil
                }
            }
        }

        return (uuidLabel, identityLabel)
    }

    /// Matches the given `SecIdentity` with what is already available in the keychain
    /// and returns its identifying data if found, so an existing data entry can be looked up.
    /// - Parameter secIdentity: The identity to search for in the keychain
    /// - Returns: The data reference for the given identity, if found, or nil,
    /// if not
    private func matchExisting(secIdentity: SecIdentity) -> String? {
        let existingTuples = listExisting()

        for (uuidString, someSecIdentity) in existingTuples {
            if CFEqual(secIdentity, someSecIdentity) {
                return uuidString
            }
        }

        return nil
    }

    /// - Returns: True If the client certificate is still used by an account.
    /// - Parameter clientCertificate: The client certificate to check
    private func isStillInUse(clientCertificate: CdClientCertificate) -> Bool {
        guard let creds = clientCertificate.serverCredential?.allObjects as? [CdServerCredentials] else {
            return false
        }
        for cred in creds {
            guard let servers = cred.servers?.allObjects as? [CdServer] else {
                continue
            }
            for server in servers {
                if server.account != nil {
                    // Still connected to an account
                    return true
                }
            }
        }
        return false
    }
}

