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

    /// Enables or disable the use of the echo protocol.
    ///
    /// The protocol is enabled by default.
    public func setStoreSecurely(newValue: Bool) {
        //In MDM we have only one account.
        if let account = Account.all().first {
            account.imapServer?.manuallyTrusted = !newValue
            account.session.commit()
        }
    }
}
