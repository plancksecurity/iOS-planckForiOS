//
//  VerifyIdentityViewModel.swift
//  planckForiOS
//
//  Created by Martin Brude on 14/12/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
#if EXT_SHARE
import MessageModelForAppExtensions
import PlanckToolboxForExtensions
#else
import MessageModel
import PlanckToolbox
#endif

struct VerifyIdentityViewModel {

    // This is the action the user decides.
    // To accept or to reject the trustwords.
    var action: VerificationAction?
    
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

    public func getVerificationResultMessage(partner: String) -> String {
        guard let decision = action else {
            Log.shared.errorAndCrash("The user decision must be set first")
            return ""
        }
        return decision == .accept ?
        NSLocalizedString("\(partner) is now verified", comment: "Partner is verified") :
        NSLocalizedString("\(partner) is now Dangerous email partner.\nWe recommend to contact your IT support of your operational team to investigate", comment: "Partner is Dangerous")
    }
    
    public func getVerificationMessage(partner: String) -> String {
        guard let decision = action else {
            Log.shared.errorAndCrash("The user decision must be set first")
            return ""
        }
        return decision == .accept ? getConfirmationVerificationMessage(partner: partner) : getRejectVerificationMessage(partner: partner)
    }
    
    private func getConfirmationVerificationMessage(partner: String) -> String {
        let text = """
        Trustwords or fingerprints are matching, this means that it is secure to communicate with \(partner) identity.
        We recommend to press Yes, Confirm, marking \(partner) as verified.
        """
        return NSLocalizedString(text, comment: text)
    }

    private func getRejectVerificationMessage(partner: String) -> String {
        let text = """
        Trustwords or fingerprints are not matching, this could indicate that someone is trying to imitate yours or \(partner) identity. We recommend to press Yes, Reject, marking \(partner) as Dangerous, and to contact your IT support on your operational security team to investigate.
        """
        return NSLocalizedString(text, comment: text)
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

    public var cancelButtonTitle: String {
        return NSLocalizedString("Cancel", comment: "Cancel button title")
    }

    public var confirmButtonTitle: String {
        return NSLocalizedString("Confirm", comment: "Confirm button title")
    }

    public var reconfirmButtonTitle: String {
        return NSLocalizedString("Yes, confirm", comment: "Re Confirm button title")
    }
    
    public var confirmRejectionButtonTitle: String {
        return NSLocalizedString("Yes, reject", comment: "Re Confirm rejection button title")
    }
  
    public var rejectButtonTitle: String {
        return NSLocalizedString("Reject", comment: "Reject button title")
    }

    public var actionButtonTitle: String {
        guard let decision = action else {
            Log.shared.errorAndCrash("The user decision must be set first")
            return ""
        }
        return decision == .accept ? NSLocalizedString("Yes, confirm", comment: "Confirm button title") : NSLocalizedString("Yes, reject", comment: "Reject button title")
    }
    
    public func handleTrustwordsRejection(message: Message) {
        guard let folder = Folder.getSuspiciousFolder(account: message.parent.account) else {
            Log.shared.errorAndCrash("Suspicious folder not found")
            return
        }
        Message.move(messages: [message], to: folder)
    }
}
