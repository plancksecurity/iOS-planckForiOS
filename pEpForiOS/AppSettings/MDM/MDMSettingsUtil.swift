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

    public func configure(completion: @escaping (Result<Void, Error>) -> Void) {
        MediaKeysUtil().configure(mediaKeyDictionaries: AppSettings.shared.mdmMediaKeys) { result in
            EchoProtocolUtil().enableEchoProtocol(enabled: AppSettings.shared.mdmEchoProtocolEnabled)
            TrustedServerUtil().setStoreSecurely(newValue: AppSettings.shared.mdmPEPSaveEncryptedOnServerEnabled)
            ExtraKeysUtil().configure(extraKeyDictionaries: AppSettings.shared.mdmPEPExtraKeys)
            completion(result)
        }
    }
}
