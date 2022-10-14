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

    static let kExtraKeyFingerprint = "extra_key_fingerprint"
    static let kExtraKeyKey = "extra_key_material"

    /// Expose the init outside MM.
    public init() {}

    /// Configure extra keys.
    ///
    /// For the format, please see `MDMSettingsProtocol.mdmPEPExtraKeys`.
    public func configure(extraKeyDictionaries: [[String:String]]) {
        //TODO: handle extra_key_material
        let keys: [String] = extraKeyDictionaries.compactMap { dict in
            guard let key = dict[ExtraKeysUtil.kExtraKeyKey] else {
                return nil
            }
            return key
        }

        keys.forEach { key in
            PEPSession().importKey(key) { error in
                Log.shared.error(error: error)
            } successCallback: { identities in
                Log.shared.info("importKey successful", identities)
                let allFingerprints: [String] = extraKeyDictionaries.compactMap { dict in
                    guard let key = dict[ExtraKeysUtil.kExtraKeyFingerprint] else {
                        return nil
                    }
                    return key
                }
                let thereIsAMatchingIdentity = identities.contains { identity in
                    return allFingerprints.contains(identity.fingerPrint ?? "")
                }
                if thereIsAMatchingIdentity {
                    Log.shared.info("There is at least one identity with a matching fingerprint")
                }
            }
        }
    }
}
