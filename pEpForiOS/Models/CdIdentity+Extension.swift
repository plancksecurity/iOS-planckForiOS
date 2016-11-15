//
//  CdIdentity+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension CdIdentity {
    public static func create(
        address: String, userName: String? = nil, userID: String?,
        isMySelf: Bool = false) -> CdIdentity {
        var dict: [String : Any] = ["address": address, "isMySelf": isMySelf]
        if let un = userName {
            dict["userName"] = un
        }
        if let uid = userName {
            dict["userID"] = uid
        }
        return CdIdentity.create(
            with: dict)

    }
}
