//
//  TrustedServerUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 5/10/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

public class TrustedServerUtil {

    /// Expose the init outside MM.
    public init() {}

    /// If disabled, an uncrypted copy of each message is sotred on the server. 
    public func setStoreSecurely(newValue: Bool) {
        // Note that this is only correct for MDM with only one account.
        if let account = Account.all().first {
            account.imapServer?.manuallyTrusted = !newValue
            account.session.commit()
        }
    }
}
