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

class UIUtils {

    /// Converts the error to a user frienldy DisplayUserError and presents it to the user
    ///
    /// - Parameters:
    ///   - error: error to preset to user
    static public func show(error: Error) {
        Log.shared.info("May or may not display error to user: (interpolate) %@", "\(error)")

        if let pEpError = error as? BackgroundError.PepError {
            show(pEpError: pEpError)
        } else {
           show(unspecifiedError: error)
        }
    }
}

// MARK: - Private

extension UIUtils {

    /// Whether or not a passphrase related alert is currently shown.
    /// - note: It is save to call that from any queue.
    static private var isCurrentlyShowingPassphraseInputAlert: Bool {
        var result = false

        let block: ()->Void = {
            guard let topVC = UIApplication.currentlyVisibleViewController() else {
                Log.shared.errorAndCrash("No VC shown?")
                return
            }
            if let shownIdentifiableAlertController = topVC as? IdentifiableAlertController {
                if shownIdentifiableAlertController.identifier == .passphraseAlert {
                    result = true
                    return
                }
            }
        }

        if Thread.current != Thread.main {
            DispatchQueue.main.sync {
                block()
            }
        } else {
            block()
        }
        return result
    }

    static private func show(pEpError: BackgroundError.PepError) {
        //BUFF: should not be called any more. The Adapter & PassphraseProviderDelegate will handle that so in theory no background OP will ever get that error.
        //RM if proven obsolete
        
//        guard !isCurrentlyShowingPassphraseInputAlert else {
//            // A passphrase alert is already shown. Do not show a second one on top of it.
//            // Do nothing instead.
//            return
//        }
//        switch pEpError {
//        case .passphraseRequired:
//            DispatchQueue.main.async {
//                guard !isCurrentlyShowingPassphraseInputAlert else {
//                    // A passphrase alert is already shown. Do not show a second one on top of it.
//                    // Do nothing instead.
//                    return
//                }
//                showPassphraseRequiredAlert()
//            }
//        case .wrongPassphrase:
//            DispatchQueue.main.async {
//                guard !isCurrentlyShowingPassphraseInputAlert else {
//                    // A passphrase alert is already shown. Do not show a second one on top of it.
//                    // Do nothing instead.
//                    return
//                }
//                showWrongPassphraseAlert()
//            }
//        }
    }

    static private func show(unspecifiedError error: Error) {
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
