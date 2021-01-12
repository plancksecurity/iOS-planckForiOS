//
//  ImapFlagsUtility.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 25/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

struct ImapFlagsUtility {

    /**
     This code can be used by both core data classes and model.
     */
    static func int16(
        answered: Bool, draft: Bool, flagged: Bool, recent: Bool, seen: Bool,
        deleted: Bool) -> Int16 {
        var c: Int16 = 0;
        c = answered == false ? c + 0 : c + 1
        c = draft == false ? c + 0 : c + 2
        c = flagged == false ? c + 0 : c + 4
        c = recent == false ? c + 0 : c + 8
        c = seen == false ? c + 0 : c + 16
        c = deleted == false ? c + 0 : c + 32
        return c
    }

}
