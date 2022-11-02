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
    public func configure(mediaKeyDictionaries: [[String:String]],
                          completion: @escaping (Result<Void, Error>) -> Void) {

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

        MediaAndExtraKeysImportUtil.importKeys(allFingerprints: allFingerprints,
                                               keys: keys,
                                               completion: completion)
    }
}
