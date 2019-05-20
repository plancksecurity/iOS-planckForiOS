//
//  CWInternetAddress+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PantomimeFramework
import MessageModel

extension CWInternetAddress {
    //rm. dead code
//    func identity(userID: String?) -> Identity {
//        return Identity.create(address: address(), userID: userID,
//                               userName: personal()?.fullyUnquoted())
//    }

    func cdIdentity(userID: String?, context: NSManagedObjectContext) -> CdIdentity {
        let cdIdent = CdIdentity(context: context)
        cdIdent.address = address()
        cdIdent.userID = userID
        cdIdent.userName = personal()?.fullyUnquoted()
        return cdIdent
    }
}
