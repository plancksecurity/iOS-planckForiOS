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

    /// Expose the init outside MM.
    public init() {}

    /// Configure MediaKeys.
    /// The media keys must follow the format: [pattern:fingerpint]
    public func configureMediaKeys(keys: [String:String]) {
        let objKeys = keys.map( {PEPMediaKeyPair(pattern: $0, fingerprint: $1) } )
        PEPObjCAdapter.configureMediaKeys(objKeys)
    }
}

