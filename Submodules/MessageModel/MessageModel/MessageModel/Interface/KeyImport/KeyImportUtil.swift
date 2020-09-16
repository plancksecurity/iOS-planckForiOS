//
//  KeyImportUtil.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

public class KeyImportUtil {
    public init() {}
}

extension KeyImportUtil {
    /// Errors that can occur when importing a key.
    public enum ImportError: Error {
        /// The key could not even be loaded
        case cannotLoadKey

        /// The key could be loadad, but not processed
        case malformedKey
    }
}

extension KeyImportUtil {
    /// Errors that can occur when setting an (already imported) key as own key.
    public enum SetOwnKeyError: Error {
        /// No matching account could be found
        case noMatchingAccount

        /// The key could not be set as an own key for other reasons,
        /// e.g. there was an error in the engine
        case cannotSetOwnKey
    }
}

extension KeyImportUtil {
    public struct KeyData: Hashable {
        public let address: String
        public let fingerprint: String
        public let userName: String

        init(address: String, fingerprint: String, userName: String) {
            self.address = address
            self.fingerprint = fingerprint
            self.userName = userName
        }
    }
}

extension KeyImportUtil: KeyImportUtilProtocol {
    public func importKey(url: URL,
                          errorCallback: @escaping (Error) -> (),
                          completion: @escaping ([KeyData]) -> ()) {
        guard let dataString = try? String(contentsOf: url) else {
            errorCallback(ImportError.cannotLoadKey)
            return
        }

        PEPSession().importKey(dataString,
                                    errorCallback: { error in
                                        errorCallback(ImportError.malformedKey)
        }) { identities in
            guard !identities.isEmpty else {
                // Importing a key with 0 identities doesn't make sense, signal an error
                errorCallback(ImportError.malformedKey)
                return
            }

            var identityFoundWithMissingData = false
            var keyDatas = [KeyData]()
            var keyDataSet = Set<KeyData>()

            for identity in identities {
                guard let fingerprint = identity.fingerPrint else {
                    identityFoundWithMissingData = true
                    break
                }
                guard let userName = identity.userName else {
                    identityFoundWithMissingData = true
                    break
                }
                let theKeyData = KeyData(address: identity.address,
                                         fingerprint: fingerprint,
                                         userName: userName)
                if !keyDataSet.contains(theKeyData) {
                    keyDatas.append(theKeyData)
                    keyDataSet.insert(theKeyData)
                }
            }

            guard !identityFoundWithMissingData else {
                // Consider identities without fingerprint an error
                errorCallback(ImportError.malformedKey)
                return
            }

            completion(keyDatas)
        }
    }

    public func setOwnKey(userName: String,
                          address: String,
                          fingerprint: String,
                          errorCallback: @escaping (Error) -> (),
                          callback: @escaping () -> ()) {
        let pEpId = PEPIdentity(address: address,
                                userID: CdIdentity.pEpOwnUserID,
                                userName: userName,
                                isOwn: true)
        PEPSession().setOwnKey(pEpId,
                                    fingerprint: fingerprint,
                                    errorCallback: errorCallback) {
                                        let moc = Stack.shared.newPrivateConcurrentContext
                                        moc.performAndWait {
                                            //BUFF: commented out as I understood volker we must not do that. The imported key could be too short and it will not be used for instance. In this case we would have an own identity without key. IOS-2405
//                                            CdIdentity.updateOrCreate(withAddress: address,
//                                                                      userID: CdIdentity.pEpOwnUserID,
//                                                                      addressBookID: nil,
//                                                                      userName: userName,
//                                                                      context: moc)
//                                            moc.saveAndLogErrors()
                                            if let existingCdIdentity = CdIdentity.search(address: address, context: moc),
                                                let belongingAccount = existingCdIdentity.accounts?.allObjects.first as? CdAccount {
                                                // A new key has been set for an existing account. Try to re-decrypt all yet undecryptable messages.
                                                CdMessage.markAllUndecryptableMessagesForRetryDecrypt(for: belongingAccount, context: moc)
                                                moc.saveAndLogErrors()
                                            }
                                            callback()
                                        }
        }
    }
}
