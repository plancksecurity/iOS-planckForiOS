//
//  PEPAlertViewControllerWithTextView+SetOwnKey.swift
//  pEp
//
//  Created by Martín Brude on 23/12/20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension PEPAlertWithTextViewsViewController {

    /// - Returns: The alert view controller to set the own key already configured
    public static func getSetOwnKeyAlertView(callback: @escaping (String?, String?) -> Void) -> PEPAlertWithTextViewsViewController? {
        let title = NSLocalizedString("Set Own Key", comment: "Set Own Key - Alert View Title")
        let message = NSLocalizedString("If the private key that you want to use has already been imported (e.g. by sending it to p≡p in an encrypted email), you can set the key as own key. Enter the Fingerprint of the key and confirm.", comment: "Set Own Key - Alert View Message")
        let pepAlertViewController =
            PEPAlertWithTextViewsViewController.fromStoryboard(title: title, message: message)
        let cancelTitle = NSLocalizedString("Cancel", comment: "Alert View Cancel Button title")
        let cancelAction = PEPUIAlertAction(title: cancelTitle,
                                            style: .pEpTextDark,
                                            handler: { alert in
                                                pepAlertViewController?.dismiss(animated: true)
                                            })
        let okTitle = NSLocalizedString("OK", comment: "Alert View OK Button title")
        let okAction = PEPUIAlertAction(title: okTitle,
                                        style: .pEpTextDark,
                                        handler: { alert in
                                            pepAlertViewController?.dismiss(animated: true, completion: {
                                                callback(pepAlertViewController?.emailTextView.text, pepAlertViewController?.fingerprintTextView.text)
                                            })
                                        })
        pepAlertViewController?.add(action: cancelAction)
        pepAlertViewController?.add(action: okAction)
        pepAlertViewController?.fingerprintPlaceholderText = "46A5-AB72-7A55-E1AA-1D19-C5A9-C399-B378-64E9"
        pepAlertViewController?.emailPlaceholderText = NSLocalizedString("Email", comment: "Email placeholder")
        DispatchQueue.main.async {
            pepAlertViewController?.modalPresentationStyle = .overFullScreen
            pepAlertViewController?.modalTransitionStyle = .crossDissolve
        }
        return pepAlertViewController
    }
}
