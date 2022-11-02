//
//  ExtraKeysUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 14/10/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapter_iOS
import PEPObjCTypes_iOS
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

public class ExtraKeysUtil {
    enum ExtraKeysImportError: Error {
        /// The key material did not match the fingerprint.
        case noMatchingFingerprint
    }

    static let kExtraKeyFingerprint = "extra_key_fingerprint"
    static let kExtraKeyMaterial = "extra_key_material"

    /// Expose the init outside MM.
    public init() {}

    /// Configure extra keys.
    ///
    /// Only the key material gets imported here, the information about which keys to use as extra keys
    /// is read from the settings every time it's needed (e.g., on encrypting messages,
    /// and also on decrypting them in order to decide about a potential re-upload).
    ///
    /// For the format, please see `MDMSettingsProtocol.mdmPEPExtraKeys`.
    public func configure(extraKeyDictionaries: [[String:String]],
                          completion: @escaping (Result<Void, Error>) -> Void) {
        let keys: [String] = extraKeyDictionaries.compactMap { dict in
            guard let key = dict[ExtraKeysUtil.kExtraKeyMaterial] else {
                return nil
            }
            return key
        }

        // Extra key material can't get removed, so if there are no keys to import,
        // there's nothing to be done.
        if keys.isEmpty {
            completion(.success(()))
            return
        }

        let allFingerprintsList: [String] = extraKeyDictionaries.compactMap { dict in
            guard let key = dict[ExtraKeysUtil.kExtraKeyFingerprint] else {
                return nil
            }
            return key
        }.filter { $0 != "" }
        let allFingerprints = Set(allFingerprintsList)

        MediaKeysUtil.importKeys(allFingerprints: allFingerprints, keys: keys, completion: completion)
    }
}
