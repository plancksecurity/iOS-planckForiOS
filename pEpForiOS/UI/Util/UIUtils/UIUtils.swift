//
//  UIUtils.swift
//  pEp
//pde
//  Created by Andreas Buff on 29.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel
import ContactsUI
import pEpIOSToolbox

struct UIUtils {

    /// Converts the error to a user frienldy DisplayUserError and presents it to the user
    ///
    /// - Parameters:
    ///   - error: error to preset to user
    static public func show(error: Error) {
        Log.shared.info("May or may not display error to user: (interpolate) %@", "\(error)")

        if let pEpError = error as? BackgroundError.PepError {
            guard !isCurrentlyShowingPassphraseInputAlert else {
                // A passphrase alert is already shown. Do not show a second one on top of it.
                // Do nothing instead.
                return
            }
            switch pEpError {
            case .passphraseRequired:
                DispatchQueue.main.async {
                    guard !isCurrentlyShowingPassphraseInputAlert else {
                        // A passphrase alert is already shown. Do not show a second one on top of it.
                        // Do nothing instead.
                        return
                    }
                    showPassphraseRequiredAlert()
                }
            case .wrongPassphrase:
                DispatchQueue.main.async {
                    guard !isCurrentlyShowingPassphraseInputAlert else {
                        // A passphrase alert is already shown. Do not show a second one on top of it.
                        // Do nothing instead.
                        return
                    }
                    showPassphraseWrongAlert()
                }
            }
        } else {
            guard let displayError = DisplayUserError(withError: error) else {
                // Do nothing. The error type is not suitable to bother the user with.
                return
            }
            DispatchQueue.main.async {
                showAlertWithOnlyPositiveButton(title: displayError.title,
                                                message: displayError.errorDescription)
            }
        }
    }
}

// MARK: - Private

extension UIUtils {

    static private var isCurrentlyShowingPassphraseInputAlert: Bool {
        guard let topVC = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC shown?")
            return false
        }
        if let shownIdentifiableAlertController = topVC as? IdentifiableAlertController {
            if shownIdentifiableAlertController.identifier == .passphraseAlert {
                return true
            }
        }
        return false
    }
}
