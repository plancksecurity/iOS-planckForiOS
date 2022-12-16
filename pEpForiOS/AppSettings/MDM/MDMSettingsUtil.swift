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
    /// - Note: For some of these settings it's vital that they are set, e.g. at DB level, _before_ the corresponding
    /// service starts up the first time, e.g. `KeySyncService`.
    public func configure(completion: @escaping (Result<Void, Error>) -> Void) {
        configureUserSpace()

        TrustedServerUtil().setStoreSecurely(newValue: AppSettings.shared.mdmPEPSaveEncryptedOnServerEnabled)
        KeySyncSettingsUtil().configureKeySync(enabled: AppSettings.shared.mdmPEPSyncAccountEnabled)
        EchoProtocolUtil().enableEchoProtocol(enabled: AppSettings.shared.mdmEchoProtocolEnabled)

        ExtraKeysUtil().configure(extraKeyDictionaries: AppSettings.shared.mdmPEPExtraKeys) { result1 in
            // Note that an error in result1 will influence the final result,
            // but does not impede the following code.
            MediaKeysUtil().configure(mediaKeyDictionaries: AppSettings.shared.mdmMediaKeys) { result2 in
                switch result1 {
                case .success(_): completion(result2)
                case .failure(_): completion(result1)
                }
            }
        }
    }

    /// Transfer MDM configuration into the "user space configuration", that has existed before MDM support
    /// was introduced and is still needed in case there is no MDM.
    private func configureUserSpace() {
        AppSettings.shared.keySyncEnabled = AppSettings.shared.mdmPEPSyncAccountEnabled
    }
}
