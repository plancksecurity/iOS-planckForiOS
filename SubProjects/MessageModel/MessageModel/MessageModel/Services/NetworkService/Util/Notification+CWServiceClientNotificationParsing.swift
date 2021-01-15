//
//  Notification+CWServiceClientNotificationParsing.swift
//  pEpForiOS
//
//  Created by buff on 28.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import PantomimeFramework

/// Parses notifications sent by CWServiceClient protocol methods for actual error messages.
extension Notification {
    func parseErrorMessageBadResponse() -> String {
        guard let pantomimeError = self.userInfo?[PantomimeErrorInfo] as? [String:String],
            let errorMsg = pantomimeError[PantomimeBadResponseInfoKey]
            else {
                return "Bad response"
        }

        return errorMsg
    }
}
