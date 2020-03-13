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

    /// Converts the error to a user frienldy DisplayUserError and presents it to the user
    ///
    /// - Parameters:
    ///   - error: error to preset to user
    ///   - vc: ViewController to present the error on
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

    /// On iPads, an UIAlertController must have `popoverPresentationController` set.
    ///
    /// - Parameters:
    ///   - actionSheet: popover to set anchor to
    ///   - presentingViewController: view controller the popover should be presented on
    static private func setIPadAnchor(for actionSheet: UIAlertController, //BUFF: move
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
                               appConfig: appConfig)
        })
        //
        let addTitle = NSLocalizedString("Add to Contacts",
                                         comment:
            "UIUtils.presentActionSheetWithContactOptions.button.title Add to Contacts")
        alertSheet.addAction(UIAlertAction(title: addTitle, style: .default) { (action) in
            presentAddToContactsView(for: contact, appConfig: appConfig)
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
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(alertSheet, animated: true, completion: nil)
    }

    // MARK: - Settings Presentation

    static func presentSettings(appConfig: AppConfig) {
        guard let vc = UIStoryboard.init(name: "Settings", bundle: Bundle.main).instantiateViewController(withIdentifier: SettingsTableViewController.storyboardId) as? SettingsTableViewController else {
            Log.shared.errorAndCrash("No controller")
            return
        }
        vc.appConfig = appConfig
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Alerts

extension UIUtils {

    /// Shows an alert with "OK" button only.
    /// - Parameters:
    ///   - title: alert title
    ///   - message: alert message
    ///   - vc: viewController to present alert on
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
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(alertView, animated: true, completion: nil)
    }

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

        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(alertView, animated: true, completion: nil)
    }
}

// MARK: - Compose View

extension UIUtils {
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
                                   appConfig: AppConfig) {
        let address = url?.firstRecipientAddress()
        if url != nil && address == nil {
            // A URL has been passed, but it is no valid mailto URL.
            return
        }

        presentComposeView(forRecipientWithAddress: address,
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

        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(composeNavigationController, animated: true)
    }
}

// MARK: - Activity Indicator

extension UIUtils {

    /// Show simple UIActivityIndicatorView in midle of current view
    ///
    /// - Returns: UIActivityIndicatorView. Useful to hold for removing from super view
    @discardableResult
    static public func showActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return activityIndicator
        }
        let view: UIView = presenterVc.view
        view.addSubview(activityIndicator)

        NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal,
                           toItem: view, attribute: .centerX, multiplier: 1,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal,
                           toItem: view, attribute: .centerY, multiplier: 1,
                           constant: 0).isActive = true
        return activityIndicator
    }
}

// MARK: - Contacts Related

extension UIUtils {

    // MARK: - Add to Contacts View

    /// Modally presents a "Add to Contacts" view for a given contact.
    ///
    /// - Parameters:
    ///   - contact: contact to show "Add to Contacts" view for
    ///   - viewController:  presenting view controller
    ///   - appConfig: AppConfig to forward
    static func presentAddToContactsView(for contact: Identity,
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
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(navigationController, animated: true, completion: nil)
    }

    // MARK: - Contact Handling Action Sheet

    /// Presents action sheet with all available custom actions for a given url.
    /// Currently the only URL scheme custom actions exist for is mailto:
    ///
    /// - Parameters:
    ///   - url: url to show custom actions for
    ///   - viewController: viewcontroller to present action view controllers on (if requiered)
    ///   - appConfig: AppConfig to forward to potentionally created viewControllers
    static public func presentActionSheetWithContactOptions(forUrl url: URL,
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
                                             at: rect,
                                             at: view,
                                             appConfig: appConfig)
    }
}
