//
//  VerifyIdentityViewModel.swift
//  planckForiOS
//
//  Created by Martin Brude on 14/12/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation

struct VerifyIdentityViewModel {

    init(isCommunicationPartnerVerified: Bool) {
        self.shouldManageTrust = isCommunicationPartnerVerified
    }

    public private(set) var shouldManageTrust: Bool = false
    
    public var title: String {
        return NSLocalizedString("Verify Identity", comment: "Verify Identity - Modal view title")
    }

    public var messageText: String {
        return NSLocalizedString("Ask your partner in person or over the phone: What are your Trustwords? Then compare the to the correct answer shown below", comment: "Instructions to verify Identity")
    }
    
    public var trustwordsTitle: String {
        return NSLocalizedString("Trustwords", comment: "Trustwords")
    }

    public var fingerprintTitle: String {
        return NSLocalizedString("Fingerprint", comment: "Fingerprint")
    }
    
    public var closeButtonTitle: String {
        return NSLocalizedString("Close", comment: "Close button title")
    }

}
