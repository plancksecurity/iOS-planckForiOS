//
//  ExtraKeysUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 14/10/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapter_iOS

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
    /// For the format, please see `MDMSettingsProtocol.mdmPEPExtraKeys`.
    public func configure(extraKeyDictionaries: [[String:String]],
                          completion: @escaping (Result<Void, Error>) -> Void) {
        let keys: [String] = extraKeyDictionaries.compactMap { dict in
            guard let key = dict[ExtraKeysUtil.kExtraKeyMaterial] else {
                return nil
            }
            return key
        }

        let allFingerprintsList: [String] = extraKeyDictionaries.compactMap { dict in
            guard let key = dict[ExtraKeysUtil.kExtraKeyFingerprint] else {
                return nil
            }
            return key
        }.filter { $0 != "" }

        let allFingerprints = Set(allFingerprintsList)

        let ses = Session()
        ses.perform {
            for fingprint in allFingerprints {
                do {
                    try ExtraKey.store(fpr: fingprint, in: ses)
                } catch {
                    // The implementation may throw ExtraKeysError.invalidFPR.
                    // Unless we have a feedback mechanism to the (MDM) admin, ignore.
                    Log.shared.error(error: error)
                }
            }
            MediaAndExtraKeysImportUtil.importKeys(allFingerprints: allFingerprints,
                                                   keys: keys,
                                                   completion: completion)
        }
    }
}
