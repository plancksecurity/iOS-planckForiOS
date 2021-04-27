//
//  Message+Extension.swift
//  pEp
//
//  Created by Martín Brude on 27/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {

    /// Returns the Tos recipients, already deduped.
    public var uniqueTos: [Identity] {
        return to.allObjects.uniques
    }

    /// Returns the CCs recipients, already deduped.
    public var uniqueCcs: [Identity] {
        return cc.allObjects.uniques
    }

    /// Returns the BCCs recipients, already deduped.
    public var uniqueBccs: [Identity] {
        return bcc.allObjects.uniques
    }

    /// Returns all the recipients, already deduped.
    public var allRecipientsOrdered: [Identity] {
        return uniqueTos + uniqueCcs + uniqueBccs
    }
}
