//
//  UIUtils.swift
//  pEp
//
//  Created by Andreas Buff on 29.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel
import ContactsUI

struct UIUtils {
    
    /// Converts the error to a user frienldy DisplayUserError and presents it to the user
    ///
    /// - Parameters:
    ///   - error: error to preset to user
    ///   - vc: ViewController to present the error on
    static func show(error: Error, inViewController vc: UIViewController) {
        Log.shared.errorComponent(#function, message: "Will display error to user: \(error)")
        guard let displayError = DisplayUserError(withError: error) else {
            // Do nothing. The error type is not suitable to bother the user with.
            return
        }
        showAlertWithOnlyPositiveButton(title: displayError.title,
                                        message: displayError.errorDescription,
                                        inViewController: vc)
    }

    static func showAlertWithOnlyPositiveButton(title: String?, message: String?,
                                                inViewController vc: UIViewController) {
        // Do not show alerts when app is in background.
        if UIApplication.shared.applicationState != .active {
            #if DEBUG
                // show alert in background when in debug.
            #else
                return
            #endif
        }
        let alertView = UIAlertController.pEpAlertController(title: title,
                                                             message: message,
                                                             preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:
            "General alert positive button"),
                                          style: .default,
                                          handler: nil))
        vc.present(alertView, animated: true, completion: nil)
    }

    // MARK: - Compose View

    static func presentComposeView(forRecipientInUrl url: URL,
                                   on viewController: UIViewController,
                                   appConfig: AppConfig) {
        let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
        guard
            url.scheme == UrlClickHandler.Scheme.mailto.rawValue,
            let address = url.firstRecipientAddress(),
            let composeNavigationController = storyboard.instantiateViewController(withIdentifier:
                Constants.composeSceneStoryboardId) as? UINavigationController,
            let composeVc = composeNavigationController.rootViewController
                as? ComposeTableViewController
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Missing required data")
                return
        }
        composeVc.appConfig = appConfig
        composeVc.composeMode = .normal
        let to = Identity(address: address)
        composeVc.prefilledTo = to
        viewController.present(composeNavigationController, animated: true)
    }

    // MARK: - Add to Contacts View

    static func presentAddToContactsView(for contact: Identity,
                                         on viewController: UIViewController,
                                         appConfig: AppConfig) {
        let storyboard = UIStoryboard(name: Constants.addToContactsStoryboard, bundle: nil)
        guard let contactVc = storyboard.instantiateViewController(withIdentifier:
            AddToContactsViewController.storyboardId) as? AddToContactsViewController else {
                Log.shared.errorAndCrash(component: #function, errorString: "Missing required data")
                return
        }
        contactVc.appConfig = appConfig
        contactVc.emailAddress = contact.address
        if let _ = viewController.navigationController {
            viewController.present(contactVc, animated: true, completion: nil)
        } else {
            let navigationController = UINavigationController(rootViewController: contactVc)
            viewController.present(navigationController, animated: true, completion: nil)
        }
    }

    static func presentActionSheetWithContactOptions(forUrl url: URL,
                                                     on viewController: UIViewController,
                                                     appConfig: AppConfig) {
        guard let _ = UrlClickHandler.Scheme(for: url) else {
            Log.shared.errorAndCrash(component: #function, errorString: "Unsupported scheme")
            return
        }
        guard let address = url.firstRecipientAddress() else {
            Log.shared.errorAndCrash(component: #function, errorString: "No address")
            return
        }
        let contact = Identity(address: address)

        let alerSheet = UIAlertController.init(title: nil,
                                               message: nil,
                                               preferredStyle: .actionSheet)
        //
        let newMailtitle = NSLocalizedString("New Mail Message",
                                              comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title New Mail Message")
        alerSheet.addAction(UIAlertAction.init(title: newMailtitle, style: .default) { (action) in
            presentComposeView(forRecipientInUrl: url, on: viewController, appConfig: appConfig)
        })
        //
        let addTitle = NSLocalizedString("Add to Contacts",
                                              comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title Add to Contacts")
        alerSheet.addAction(UIAlertAction.init(title: addTitle, style: .default, handler: { (action) in
            presentAddToContactsView(for: contact, on: viewController, appConfig: appConfig)
        }))
        //
        let copyTitle = NSLocalizedString("Copy Email",
                                         comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title Copy Email")
        alerSheet.addAction(UIAlertAction.init(title: copyTitle, style: .default, handler: { (action) in
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "unimplemented stub - copy action")
        }))
        //
        let cancelTitle = NSLocalizedString("Cancel",
                                          comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title Cancel")
        alerSheet.addAction(UIAlertAction.init(title: cancelTitle, style: .cancel, handler: { (action) in
            print("cancel action")
        }))
        viewController.present(alerSheet, animated: true, completion: nil)
    }
}
