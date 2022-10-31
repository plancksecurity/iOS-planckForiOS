//
//  MDMSettingsUtil.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 25.10.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/// Bundles account/engine setup together, so the code can be shared by both MDM-account setup logic
/// and the MDM-setting changes.
public class MDMSettingsUtil {
    /// Expose the init to outsiders.
    public init() {}

    /// - Note: For some of these settings it's vital that they are set, e.g. at DB level, _before_ the corresponding
    /// service starts up the first time, e.g. `KeySyncService`.
    public func configure(completion: @escaping (Result<Void, Error>) -> Void) {
        EchoProtocolUtil().enableEchoProtocol(enabled: AppSettings.shared.mdmEchoProtocolEnabled)
        TrustedServerUtil().setStoreSecurely(newValue: AppSettings.shared.mdmPEPSaveEncryptedOnServerEnabled)
        ExtraKeysUtil().configure(extraKeyDictionaries: AppSettings.shared.mdmPEPExtraKeys)
        KeySyncSettingsUtil().configureKeySync(enabled: AppSettings.shared.mdmPEPSyncAccountEnabled)

        MediaKeysUtil().configure(mediaKeyDictionaries: AppSettings.shared.mdmMediaKeys) { result in
            completion(result)
        }
    }
}
