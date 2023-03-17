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
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

protocol TrustBannerDelegate: AnyObject {

    /// Presents the trust management view
    func presentTrustManagementView()
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
        guard let rating = message?.pEpRatingInt, rating == Rating.reliable.toInt() else {
            return false
        }
        return true
    }

    /// The button title
    public var buttonTitle: String {
        return NSLocalizedString("Tap to establish trust with this sender.", comment: "Tap to establish trust with this sender - button title")
    }

    /// Handle trust button was pressed.
    public func handleTrustButtonPressed() {
        DispatchQueue.main.async {
            guard let del = delegate else {
                Log.shared.errorAndCrash("Delegate not found")
                return
            }
            del.presentTrustManagementView()
        }
    }
}
