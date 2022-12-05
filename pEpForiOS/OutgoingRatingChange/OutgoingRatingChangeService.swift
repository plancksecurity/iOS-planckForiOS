//
//  OutgoingRatingChangeService.swift
//  pEp
//
//  Created by Martín Brude on 7/9/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

/// This service will handle changes in the outgoing rating
class OutgoingRatingChangeService: OutgoingRatingServiceProtocol {

    public func handleOutgoingRatingChange() {
        DispatchQueue.main.async {
            guard let composeViewController = UIUtils.getPresentedComposeViewControllerIfExists(),
            let vm = composeViewController.viewModel else {
                // This is a valid case.
                return
            }
            vm.ratingMayHaveChanged()
        }
    }
}
