//
//  KeySyncSettingsUtil.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 31.10.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

public class KeySyncSettingsUtil {

    public init() {}

    public func configureKeySync(enabled: Bool) {
        // Note that this is only correct for MDM with only one account.
        if let account = Account.all().first {
            account.pEpSyncEnabled = enabled
        }
    }
}
