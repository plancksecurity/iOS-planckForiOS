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

    static let kPattern = "pattern"
    static let kFingerprint = "fingerprint"
    static let kKey = "key"

    /// Expose the init outside MM.
    public init() {}

    /// Configure media keys.
    /// The media keys must follow the format: [pattern:fingerpint]
    public func configure(mediaKeyDictionaries: [[String:String]]) {
        let pairs: [PEPMediaKeyPair] = mediaKeyDictionaries.compactMap { dict in
            guard let pattern = dict[MediaKeysUtil.kPattern] else {
                return nil
            }
            guard let fingerprint = dict[MediaKeysUtil.kFingerprint] else {
                return nil
            }

            return PEPMediaKeyPair(pattern: pattern, fingerprint: fingerprint)
        }

        // TODO: Import all keys

        PEPObjCAdapter.configureMediaKeys(pairs)
    }
}

