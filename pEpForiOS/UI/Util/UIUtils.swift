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
import pEpIOSToolbox

struct UIUtils {

    /// Converts the error to a user frienldy DisplayUserError and presents it to the user.
    /// The alert is presented modally over the currently shown viewVontroller
    ///
    /// - Parameters:
    ///   - error: error to preset to user
    static func show(error: Error) {
        Log.shared.error("May or may not display error to user: (interpolate) %@", "\(error)")

        guard let displayError = DisplayUserError(withError: error) else {
            // Do nothing. The error type is not suitable to bother the user with.
            return
        }
        DispatchQueue.main.async {
            showAlertWithOnlyPositiveButton(title: displayError.title,
                                            message: displayError.errorDescription)
        }
    }

    /// Shows an alert with "OK" button only.
    /// The alert is presented modally over the currently shown viewVontroller
    /// - Parameters:
    ///   - title: alert title
    ///   - message: alert message
    ///   - completion: called when "OK" has been pressed
    static func showAlertWithOnlyPositiveButton(title: String?,
                                                message: String?,
                                                completion: (()->Void)? = nil) {
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
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment:
        "General alert positive button"),
                                     style: .default) { action in
                                        completion?()
        }
        alertView.addAction(okAction)
        guard let vc = UIApplication.topViewController() else {
            Log.shared.errorAndCrash("No top VC")
            return
        }
        vc.present(alertView, animated: true, completion: nil)
    }

    /// Shows an alert with "OK" button only.
    /// The alert is presented modally over the currently shown viewVontroller
    /// - Parameters:
    ///   - title: alert title
    ///   - message: alert message
    ///   - cancelButtonText: canel button label
    ///   - positiveButtonText: positive button label
    ///   - cancelButtonAction: executed when cancel button is pressed
    ///   - positiveButtonAction: executed when positive button is pressed
    static func showTwoButtonAlert(withTitle title: String,
                                   message: String,
                                   cancelButtonText: String = NSLocalizedString("Cancel",
                                                                                comment: "Default cancel button text"),
                                   positiveButtonText: String = NSLocalizedString("OK",
                                                                                  comment: "Default positive button text"),
                                   cancelButtonAction: @escaping ()->Void,
                                   positiveButtonAction: @escaping () -> Void) {
        let alertView = UIAlertController.pEpAlertController(title: title,
                                        message: message,
                                        preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: positiveButtonText,
                                          style: .default) { (alertAction) in
                                            positiveButtonAction()
        })
        alertView.addAction(UIAlertAction(title: cancelButtonText,
                                          style: .cancel) { (alertAction) in
                                            cancelButtonAction()
        })
        guard let vc = UIApplication.topViewController() else {
            Log.shared.errorAndCrash("No top VC")
            return
        }
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
        let address = url?.firstRecipientAddress()
        if url != nil && address == nil {
            // A URL has been passed, but it is no valid mailto URL.
            return
        }

        presentComposeView(forRecipientWithAddress: address,
                           on: viewController,
                           appConfig: appConfig)
    }

    /// Modally presents a "Compose New Mail" view.
    /// If we can parse a recipient from the url (e.g. "mailto:me@me.com") we prefill the "To:"
    /// field of the presented compose view.
    ///
    /// - Parameters:
    ///   - address: address to prefill "To:" field with
    ///   - viewController: presenting view controller
    ///   - appConfig: AppConfig to forward
    static func presentComposeView(forRecipientWithAddress address: String?,
                                   on viewController: UIViewController,
                                   appConfig: AppConfig) {
        let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
        guard
            let composeNavigationController = storyboard.instantiateViewController(withIdentifier:
                Constants.composeSceneStoryboardId) as? UINavigationController,
            let composeVc = composeNavigationController.rootViewController
                as? ComposeTableViewController
            else {
                Log.shared.errorAndCrash("Missing required data")
                return
        }
        var prefilledTo: Identity? = nil
        if let address = address {
            let to = Identity(address: address)
            to.save()
            prefilledTo = to
        }
        let composeVM = ComposeViewModel(composeMode: .normal,
                                         prefilledTo: prefilledTo,
                                         originalMessage: nil)
        composeVc.viewModel = composeVM
        composeVc.appConfig = appConfig

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
                Log.shared.errorAndCrash("Missing required data")
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
                                                     at rect: CGRect,
                                                     at view: UIView,
                                                     appConfig: AppConfig) {
        guard let _ = UrlClickHandler.Scheme(for: url) else {
            Log.shared.errorAndCrash("Unsupported scheme")
            return
        }
        guard let address = url.firstRecipientAddress() else {
            Log.shared.errorAndCrash("No address")
            return
        }
        presentActionSheetWithContactOptions(forContactWithEmailAddress: address,
                                             on: viewController,
                                             at: rect,
                                             at: view,
                                             appConfig: appConfig)
    }

    /// On iPads, an UIAlertController must have `popoverPresentationController` set.
    ///
    /// - Parameters:
    ///   - actionSheet: popover to set anchor to
    ///   - presentingViewController: view controller the popover should be presented on
    static private func setIPadAnchor(for actionSheet: UIAlertController,
                                      in rect: CGRect,
                                      at view: UIView) {

        actionSheet.popoverPresentationController?.sourceRect = rect

        actionSheet.popoverPresentationController?.sourceView = view
        actionSheet.popoverPresentationController?.permittedArrowDirections
            = UIPopoverArrowDirection.up



    }

    /// Presents action sheet with all available custom actions for a given url.
    /// Currently the only URL scheme custom actions exist for is mailto:
    ///
    /// - Parameters:
    ///   - address: address to show custom actions for
    ///   - viewController: viewcontroller to present action view controllers on (if requiered)
    ///   - appConfig: AppConfig to forward to potentionally created viewControllers
    static func presentActionSheetWithContactOptions(forContactWithEmailAddress address: String,
                                                     on viewController: UIViewController,
                                                     at rect: CGRect,
                                                     at view: UIView,
                                                     appConfig: AppConfig) {
        let contact = Identity(address: address)

        let alertSheet = UIAlertController.init(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)

        setIPadAnchor(for: alertSheet, in: rect, at: view)

        alertSheet.view.tintColor = UIColor.pEpDarkGreen
        //
        let newMailtitle = NSLocalizedString("New Mail Message",
                                             comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title New Mail Message")
        alertSheet.addAction(UIAlertAction(title: newMailtitle, style: .default) { (action) in
            presentComposeView(forRecipientWithAddress: address,
                               on: viewController,
                               appConfig: appConfig)
        })
        //
        let addTitle = NSLocalizedString("Add to Contacts",
                                         comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title Add to Contacts")
        alertSheet.addAction(UIAlertAction(title: addTitle, style: .default) { (action) in
            presentAddToContactsView(for: contact, on: viewController, appConfig: appConfig)
        })
        //
        let copyTitle = NSLocalizedString("Copy Email",
                                          comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title Copy Email")
        alertSheet.addAction(UIAlertAction(title: copyTitle, style: .default) { (action) in
            UIPasteboard.general.string = address
        })
        //
        let cancelTitle = NSLocalizedString("Cancel",
                                            comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title Cancel")
        alertSheet.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { (action) in
            print("cancel action")
        })
        viewController.present(alertSheet, animated: true, completion: nil)
    }

    // MARK: - Settings Presentation

    static func presentSettings(on viewController: UIViewController, appConfig: AppConfig) {
        guard let vc = UIStoryboard.init(name: "Settings", bundle: Bundle.main).instantiateViewController(withIdentifier: SettingsTableViewController.storyboardId) as? SettingsTableViewController else {
            Log.shared.errorAndCrash("No controller")
            return
        }
        vc.appConfig = appConfig
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
