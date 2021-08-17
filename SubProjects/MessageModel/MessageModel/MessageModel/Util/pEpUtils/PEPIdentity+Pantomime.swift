//
//  PEPIdentity+Pantomime.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import PEPObjCTypes_iOS
import PEPObjCAdapter_iOS

extension PEPIdentity {
    /// Converts a pEp identity dict to a pantomime address.
    func pantomimeAddress() -> CWInternetAddress {
        return CWInternetAddress(personal: userName, address: address)
    }

    static func add(pEpIdentities: [PEPIdentity],
                    toPantomimeMessage: CWIMAPMessage,
                    recipientType: PantomimeRecipientType) {
        let addresses = pantomimeAddresses(
            pEpIdentities: pEpIdentities, recipientType: recipientType)
        for a in addresses {
            toPantomimeMessage.addRecipient(a)
        }
    }

    /// Converts a list of pEp identities of a given receiver type to a list of pantomime recipients.
    private static func pantomimeAddresses(pEpIdentities: [PEPIdentity],
                                           recipientType: PantomimeRecipientType) -> [CWInternetAddress] {
        return pEpIdentities.map {
            let thePantomimeAddress = $0.pantomimeAddress()
            thePantomimeAddress.setType(recipientType)
            return thePantomimeAddress
        }
    }
}
