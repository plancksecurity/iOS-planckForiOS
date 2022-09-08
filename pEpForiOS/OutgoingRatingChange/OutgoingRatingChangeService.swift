//
//  OutgoingRatingChangeService.swift
//  pEp
//
//  Created by Martín Brude on 7/9/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class OutgoingRatingChangeService {

    init() {
        registerForOutgoingMessageRatingChanges()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Outgoing Messages pEpRating Changes

extension OutgoingRatingChangeService {

    private func registerForOutgoingMessageRatingChanges() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleOutgoingRatingChangeNotification(_:)),
                                               name: Notification.Name.pEpOutgoingRatingChange,
                                               object: nil)
    }

    @objc
    private func handleOutgoingRatingChangeNotification(_ notification: Notification) {
        guard let composeViewController = UIUtils.getPresentedComposeViewControllerIfExists(),
        let vm = composeViewController.viewModel else {
            // This is a valid case.
            return
        }
        DispatchQueue.main.async {
            vm.ratingMayHaveChanged()
        }
    }
}
