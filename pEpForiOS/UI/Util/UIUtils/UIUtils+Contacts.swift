//
//  UIUtils+Contacts.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

// MARK: - UIUtil+Contacts

extension UIUtils {
    /// Modally presents a "Add to Contacts" view for a given contact.
    ///
    /// - Parameters:
    ///   - contact: contact to show "Add to Contacts" view for
    static func presentAddToContactsView(for contact: Identity) {
        let storyboard = UIStoryboard(name: Constants.reusableStoryboard, bundle: nil)
        guard let contactVc = storyboard.instantiateViewController(withIdentifier:
                                                                    AddToContactsViewController.storyboardId) as? AddToContactsViewController else {
            Log.shared.errorAndCrash("Missing required data")
            return
        }
        contactVc.emailAddress = contact.address
        let navigationController = UINavigationController(rootViewController: contactVc)
        let presenterVc = UIApplication.currentlyVisibleViewController()
        presenterVc.present(navigationController, animated: true, completion: nil)
    }

    // MARK: - Contact Handling Action Sheet

    /// Presents action sheet with all available custom actions for a given url.
    /// Currently the only URL scheme custom actions exist for is mailto:
    ///
    /// - Parameters:
    ///   - url: url to show custom actions for
    ///   - rect: The sourceRect to show the action sheet in iPad.
    ///   - view: The sourceView to show the action sheet in iPad.
    static public func showActionSheetWithContactOptions(forUrl url: URL,
                                                            at rect: CGRect,
                                                            at view: UIView) {
        guard let _ = UrlClickHandler.Scheme(for: url) else {
            Log.shared.errorAndCrash("Unsupported scheme")
            return
        }
        guard let address = url.firstRecipientAddress() else {
            Log.shared.errorAndCrash("No address")
            return
        }
        showActionSheetWithContactOptions(forContactWithEmailAddress: address,
                                             at: rect,
                                             at: view)
    }
}
