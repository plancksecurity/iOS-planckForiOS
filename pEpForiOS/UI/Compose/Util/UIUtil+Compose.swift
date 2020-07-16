//
//  UIUtil+Compose.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - UIUtil+Compose

import MessageModel

extension UIUtils {

    /// Modally presents a "Compose New Mail" view.
    /// If we can parse a recipient from the url (e.g. "mailto:me@me.com") we prefill the "To:"
    /// field of the presented compose view.
    ///
    /// - Parameters:
    ///   - url: url to parse recipients from
    ///   - appConfig: AppConfig to forward
    static func presentComposeView(forRecipientInUrl url: URL?) {
        let address = url?.firstRecipientAddress()
        if url != nil && address == nil {
            // A URL has been passed, but it is no valid mailto URL.
            return
        }

        presentComposeView(forRecipientWithAddress: address)
    }

    /// Modally presents a "Compose New Mail" view.
    /// If we can parse a recipient from the url (e.g. "mailto:me@me.com") we prefill the "To:"
    /// field of the presented compose view.
    ///
    /// - Parameters:
    ///   - address: address to prefill "To:" field with
    ///   - viewController: presenting view controller
    ///   - appConfig: AppConfig to forward
    static func presentComposeView(forRecipientWithAddress address: String?) {
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
            to.session.commit()
            prefilledTo = to
        }
        let composeVM = ComposeViewModel(composeMode: .normal,
                                         prefilledTo: prefilledTo,
                                         originalMessage: nil)
        composeVc.viewModel = composeVM

        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(composeNavigationController, animated: true)
    }

    static func composeNavigationController() -> UINavigationController? {
        let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
        guard
            let composeNavigationController = storyboard.instantiateViewController(withIdentifier:
                Constants.composeSceneStoryboardId) as? UINavigationController,
            let composeVc = composeNavigationController.rootViewController
                as? ComposeTableViewController
            else {
                Log.shared.errorAndCrash("Missing required data")
                return nil
        }

        let composeVM = ComposeViewModel(composeMode: .normal,
                                         prefilledTo: nil,
                                         originalMessage: nil)
        composeVc.viewModel = composeVM

        return composeNavigationController
    }



}
