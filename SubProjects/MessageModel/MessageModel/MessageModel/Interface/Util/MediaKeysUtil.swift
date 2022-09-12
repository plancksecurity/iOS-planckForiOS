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
public protocol MediaKeysUtilProtocol: AnyObject {

    /// Configure MediaKeys.
    /// The media keys must follow the format: [pattern:fingerpint]
    func configureMediaKeys(keys: [String:String])
}

public class MediaKeysUtil: MediaKeysUtilProtocol {

    /// Expose the init outside MM.
    public init() {}

    public func configureMediaKeys(keys: [String:String]) {
        let pEpSession = PEPSession()
        let objKeys = keys.map( {PEPMediaKeyPair(pattern: $0, fingerprint: $1) } )
        do {
            try pEpSession.configureMediaKeys(objKeys)
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
    }
}

