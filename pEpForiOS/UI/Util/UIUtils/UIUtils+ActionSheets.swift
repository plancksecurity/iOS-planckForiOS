//
//  UIUtils+ActionSheets.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

// MARK: - UIUtils+ActionSheets

extension UIUtils {
    /// - Parameters:
    ///   - title: The title of the alert action
    ///   - style: The style of the alert action
    ///   - closure: The closure to be executed for the action.
    /// - Returns: An alert action.
    public static func action(_ title: String,
                              _ style: UIAlertAction.Style = .default,
                              _ closure: (() -> ())? = nil) ->  UIAlertAction {
        return UIAlertAction(title: title, style: style) { (action) in
            closure?()
        }
    }

    /// - Parameters:
    ///   - title: The title of the action sheet.
    ///   - message: The message of the action sheet
    /// - Returns: An action sheet with pEp green tint color.
    public static func actionSheet(title: String? = nil, message: String? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alertController.view.tintColor = .pEpGreen
        return alertController
    }

    /// Presents action sheet with all available custom actions for a given url.
    /// Currently the only URL scheme custom actions exist for is mailto:
    ///
    /// - Parameters:
    ///   - address: address to show custom actions for
    ///   - appConfig: AppConfig to forward to potentionally created viewControllers
    static public func showActionSheetWithContactOptions(forContactWithEmailAddress address: String,
                                                            at rect: CGRect,
                                                            at view: UIView,
                                                            appConfig: AppConfig) {
        let alertSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        setIPadAnchor(for: alertSheet, in: rect, at: view)
        alertSheet.view.tintColor = UIColor.pEpDarkGreen
        let newMailtitle = NSLocalizedString("New Mail Message", comment:
                                                "UIUtils.showActionSheetWithContactOptions.button.title New Mail Message")
        alertSheet.addAction(UIAlertAction(title: newMailtitle, style: .default) { (action) in
            let mailtoAddress = "mailto:" + address
            guard let url = URL(string: mailtoAddress) else {
                Log.shared.errorAndCrash("Invalid URL address")
                return
            }
            let mailto = Mailto(url: url)
            showComposeView(from: mailto, appConfig: appConfig)
        })
        let addTitle = NSLocalizedString("Add to Contacts", comment: "UIUtils.showActionSheetWithContactOptions.button.title Add to Contacts")
        let contact = Identity(address: address)
        alertSheet.addAction(UIAlertAction(title: addTitle, style: .default) { (action) in
            presentAddToContactsView(for: contact, appConfig: appConfig)
        })
        let copyTitle = NSLocalizedString("Copy Email", comment:
                                            "UIUtils.showActionSheetWithContactOptions.button.title Copy Email")
        alertSheet.addAction(UIAlertAction(title: copyTitle, style: .default) { (action) in
            UIPasteboard.general.string = address
        })
        let cancelTitle = NSLocalizedString("Cancel", comment:
                                                "UIUtils.showActionSheetWithContactOptions.button.title Cancel")
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { (action) in }
        alertSheet.addAction(cancelAction)
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(alertSheet, animated: true, completion: nil)
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
        actionSheet.popoverPresentationController?.permittedArrowDirections = .up
    }
}
