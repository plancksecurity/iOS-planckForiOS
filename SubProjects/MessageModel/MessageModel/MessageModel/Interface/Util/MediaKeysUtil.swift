//
//  MediaKeysUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 12/9/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapter_iOS
import PEPObjCTypes_iOS
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

/// https://dev.pep.foundation/Engine/Media%20keys
public class MediaKeysUtil {

    static let kPattern = "media_key_address_pattern"
    static let kFingerprint = "media_key_fingerprint"
    static let kKey = "media_key_material"

    /// Expose the init outside MM.
    public init() {}

    /// Configure media keys.
    ///
    /// For the format, please see `MDMSettingsProtocol.mdmMediaKeys`.
    public func configure(mediaKeyDictionaries: [[String:String]]) {

        // MARK: - Configure Media Keys

        let pairs: [PEPMediaKeyPair] = mediaKeyDictionaries.compactMap { dict in
            guard let pattern = dict[MediaKeysUtil.kPattern] else {
                return nil
            }
            guard let fingerprint = dict[MediaKeysUtil.kFingerprint] else {
                return nil
            }
            return PEPMediaKeyPair(pattern: pattern, fingerprint: fingerprint)
        }
        PEPObjCAdapter.configureMediaKeys(pairs)

        // MARK: - Import all keys

        let keys: [String] = mediaKeyDictionaries.compactMap { dict in
            guard let key = dict[MediaKeysUtil.kKey] else {
                return nil
            }
            return key
        }

        let allFingerprints = Set((pairs.map {$0.fingerprint}).filter { !$0.isEmpty })

        let importKeysGroup = DispatchGroup()

        keys.forEach { key in
            importKeysGroup.enter()
            PEPSession().importKey(key) { error in
                Log.shared.error(error: error)
                importKeysGroup.leave()
            } successCallback: { identities in
                let thereIsAMatchingIdentity = identities.contains { identity in
                    if let fingerprint = identity.fingerPrint {
                        return allFingerprints.contains(fingerprint)
                    } else {
                        return false
                    }
                }
                if !thereIsAMatchingIdentity {
                    Log.shared.logError(message: "Media key import: No identity with matching fingerprint")
                }
                importKeysGroup.leave()
            }
        }
        importKeysGroup.wait()
    }

    func importKey(allFingerprints: Set<String>,
                   key: String, completion: @escaping (Result<[PEPIdentity], Error>) -> Void) {
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
                Log.shared.logError(message: "Media key import: No identity with matching fingerprint")
            }
            completion(.success(identities))
        }
    }
}
