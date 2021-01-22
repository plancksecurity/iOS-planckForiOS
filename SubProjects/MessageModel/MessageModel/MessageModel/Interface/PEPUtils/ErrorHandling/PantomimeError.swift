//
//  PantomimeError.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

public enum PantomimeError: Error {
    /**
     Pantomime called the delegate without notification info
     */
    case missingNotification

    /**
     Pantomime called the delegate with notification info, but that is
     missing the user info
     */
    case missingUserInfo

    /**
     Pantomime called the delegate with notification info and user info,
     but it does not contain messages.
     */
    case missingMessages
}
