//
//  PEPIdentity+Pantomime.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import PEPObjCAdapterFramework

extension PEPIdentity {
    /// Converts a pEp identity dict to a pantomime address.
    func cwInternetAddress() -> CWInternetAddress {
        return CWInternetAddress(personal: userName, address: address)
    }

    static func add(pEpIdentities: [PEPIdentity],
                    toPantomimeMessage: CWIMAPMessage,
                    recipientType: PantomimeRecipientType) {
        let addresses = pantomimeAddress(
            pEpIdentities: pEpIdentities, recipientType: recipientType)
        for a in addresses {
            toPantomimeMessage.addRecipient(a)
        }
    }

    /// Converts a list of pEp identities of a given receiver type to a list of pantomime recipients.
    private static func pantomimeAddress(pEpIdentities: [PEPIdentity],
                                         recipientType: PantomimeRecipientType) -> [CWInternetAddress] {
        return pEpIdentities.map {
            let pantomimeAddress = $0.cwInternetAddress()
            pantomimeAddress.setType(recipientType)
            return pantomimeAddress
        }
    }
}
