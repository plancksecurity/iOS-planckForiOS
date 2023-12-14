//
//  VerifyIdentityViewModel.swift
//  planckForiOS
//
//  Created by Martin Brude on 14/12/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

struct VerifyIdentityViewModel {

    private var trustManagementUtil : TrustManagementUtilProtocol

    private var message: Message
    
    init(message: Message, trustManagementUtil: TrustManagementUtilProtocol? = nil) {
        self.message = message
        self.trustManagementUtil = trustManagementUtil ?? TrustManagementUtil()
    }
    
    public var title: String {
        return NSLocalizedString("Verify Identity", comment: "Verify Identity - Modal view title")
    }

    public var messageText: String {
        return NSLocalizedString("Ask your partner in person or over the phone: What are your Trustwords? Then compare the to the correct answer shown below", comment: "Instructions to verify Identity")
    }
    
    public var trustwordsTitle: String {
        return NSLocalizedString("Trustwords", comment: "Trustwords")
    }

    public var fingerprintsTitle: String {
        return NSLocalizedString("Fingerprints", comment: "Fingerprints")
    }
    
    public var closeButtonTitle: String {
        return NSLocalizedString("Close", comment: "Close button title")
    }
    
    var ownDeviceUsername: String {
        return ""
    }

    var ownDeviceTrustwords: String {
        return ""
    }
    
    var otherDeviceTrustwords: String {
        return ""
    }

    var otherDeviceUsername: String {
        return ""
    }

}
