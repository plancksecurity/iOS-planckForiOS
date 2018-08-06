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

    /// Modally presents a "Compose New Mail" view.
    /// If we can parse a recipient from the url (e.g. "mailto:me@me.com") we prefill the "To:"
    /// field of the presented compose view.
    ///
    /// - Parameters:
    ///   - url: url to parse recipients from
    ///   - viewController: presenting view controller
    ///   - appConfig: AppConfig to forward
    static func presentComposeView(forRecipientInUrl url: URL?,
                                   on viewController: UIViewController,
                                   appConfig: AppConfig) {
        let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
        guard
            let composeNavigationController = storyboard.instantiateViewController(withIdentifier:
                Constants.composeSceneStoryboardId) as? UINavigationController,
            let composeVc = composeNavigationController.rootViewController
                as? ComposeTableViewController
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Missing required data")
                return
        }
        if let url = url,
            let url.scheme == UrlClickHandler.Scheme.mailto.rawValue,
            let address = url.firstRecipientAddress() {
            let to = Identity(address: address)
            composeVc.prefilledTo = to
        }
        composeVc.appConfig = appConfig
        composeVc.composeMode = .normal

        viewController.present(composeNavigationController, animated: true)
    }

    // MARK: - Add to Contacts View

    /// Modally presents a "Add to Contacts" view for a given contact.
    ///
    /// - Parameters:
    ///   - contact: contact to show "Add to Contacts" view for
    ///   - viewController:  presenting view controller
    ///   - appConfig: AppConfig to forward
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
        let navigationController = UINavigationController(rootViewController: contactVc)
        viewController.present(navigationController, animated: true, completion: nil)
    }

    // MARK: - Contact Handling Action Sheet

    /// Presents action sheet with all available custom actions for a given url.
    /// Currently the only URL scheme custom actions exist for is mailto:
    ///
    /// - Parameters:
    ///   - url: url to show custom actions for
    ///   - viewController: viewcontroller to present action view controllers on (if requiered)
    ///   - appConfig: AppConfig to forward to potentionally created viewControllers
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
        alerSheet.view.tintColor = UIColor.pEpDarkGreen
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
