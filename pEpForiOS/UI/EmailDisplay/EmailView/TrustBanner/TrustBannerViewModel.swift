//
//  TrustBannerViewModel.swift
//  pEp
//
//  Created by Martin Brude on 7/3/23.
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

protocol TrustBannerDelegate: AnyObject {

    /// Presents the trust management view
    func presentTrustManagementView()

    /// Presents the Trust Verification view
    func presentVerificationTrustView()
}

struct TrustBannerViewModel {

    /// Delegate to communicate with the view.
    public weak var delegate: TrustBannerDelegate?

    private var message: Message?

    private var pEpProtectionModifyable: Bool

    /// Constructor
    ///
    /// - parameters:
    ///   - delegate: The delegate to communicate with the view.
    ///   - message: The message of the view.
    ///   - pEpProtectionModifyable: The delegate to communicate with the view.
    init(delegate: TrustBannerDelegate, message: Message, pEpProtectionModifyable: Bool) {
        self.delegate = delegate
        self.message = message
        self.pEpProtectionModifyable = pEpProtectionModifyable
    }

    /// Indicate whether the banner must be shown.
    /// True if it must be shown. False otherwise.
    func shouldShowTrustBanner() -> Bool {
        guard let message = message else {
            return false
        }

        /*
        // Only should show the trust banner when there is one sender and one recipient and the message is “secure” (reliable).

        guard message.pEpRatingInt == Rating.reliable.toInt() else {
            return false
        }
        */
        
        guard message.from != nil else {
            //From does not exist. The banner must be hidden.
            return false
        }

        let onlyOneToRecipient = message.to.count == 1 && message.cc.isEmpty && message.bcc.isEmpty
        if onlyOneToRecipient {
            // Only one TO recipient. The banner must be visible.
            return true
        }
        
        let onlyOneCCRecipient = message.cc.count == 1 && message.to.isEmpty && message.bcc.isEmpty
        if onlyOneCCRecipient {
            // Only one CC recipient. The banner must be visible.
            return true
        }

        let onlyOneBCCRecipient = message.bcc.count == 1 && message.to.isEmpty && message.cc.isEmpty
        if onlyOneBCCRecipient {
            // Only one BCC recipient. The banner must be visible.
            return true
        }

        // More than on recipient. The banner must be hidden.
        return false
    }

    /// The button title
    public var buttonTitle: String {
        return NSLocalizedString("Tap to verify identity with this sender.", comment: "Tap to verify identity with this sender - button title")
    }

    /// Handle trust button was pressed.
    public func handleTrustButtonPressed() {
        DispatchQueue.main.async {
            guard let del = delegate else {
                Log.shared.errorAndCrash("Delegate not found")
                return
            }
            guard let msg = message else {
                Log.shared.errorAndCrash("Message not found")
                return
            }
            let messageRating = msg.pEpRatingInt
            if messageRating == Rating.reliable.toInt() {
                del.presentTrustManagementView()
            } else {
                del.presentVerificationTrustView()
            }
        }
    }
}
