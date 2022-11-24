//
//  KeyImportUtil+MediaExtraKeys.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 02.11.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapter_iOS

class MediaAndExtraKeysImportUtil {
    enum KeyImportError: Error {
        /// The key material did not match the fingerprint.
        case noMatchingFingerprint
    }

    static func importKeys(allFingerprints: Set<String>,
                           keys: [String],
                           completion: @escaping (Result<Void, Error>) -> Void) {
        // The actual key import can only ever add keys, not remove them,
        // so we're done here if there are no keys.
        if keys.isEmpty {
            completion(.success(()))
            return
        }

        var finalError: Error?
        DispatchQueue.global().async {
            let group = DispatchGroup()
            for key in keys {
                group.enter()
                self.importKey(allFingerprints: allFingerprints,
                          key: key) { result in
                    switch(result) {
                    case .failure(let error):
                        if finalError == nil {
                            finalError = error
                        }
                    case .success():
                        break
                    }
                    group.leave()
                }
            }

            group.wait()
            if let error = finalError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    static func importKey(allFingerprints: Set<String>,
                          key: String,
                          completion: @escaping (Result<Void, Error>) -> Void) {
        PEPSession().importKey(key) { error in
            completion(.failure(error))
        } successCallback: { identities in
            let thereIsAMatchingIdentity = identities.contains { identity in
                if let fingerprint = identity.fingerPrint {
                    return allFingerprints.contains(fingerprint)
                } else {
                    return false
                }
            }
            if !thereIsAMatchingIdentity {
                completion(.failure(KeyImportError.noMatchingFingerprint))
            } else {
                completion(.success(()))
            }
        }
    }
}
