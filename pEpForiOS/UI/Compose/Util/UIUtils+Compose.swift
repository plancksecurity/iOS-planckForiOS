//
//  UIUtil+Compose.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import PlanckToolboxForExtensions
#else
import MessageModel
import PlanckToolbox
#endif

// MARK: - UIUtils+Compose

extension UIUtils {

    /// Shows the Compose View prefilled with data from Mailto.
    /// - Parameter mailto: The Mailto to populate the view.
    static public func showComposeView(from mailto: Mailto?) {
        let viewModel = ComposeViewModel.from(mailTo: mailto)
        showCompose(composeViewModel: viewModel)
    }

    /// Show compose view and prefill the From field with the email address passed by parameter.
    ///
    /// - Parameter address: The email address. If it's invalid, the From field will be empty.
    static public func showComposeView(from address: String) {
        let viewModel = ComposeViewModel.init(prefilledFromAddress: address)
        showCompose(composeViewModel: viewModel)
    }

    /// - Returns: The ComposeViewController that is presented, if exists. Nil if not.
    static public func getPresentedComposeViewControllerIfExists() -> ComposeViewController? {
        guard let currentlyShownComposeViewController = UIApplication.currentlyVisibleViewController() as? ComposeViewController else {
            return nil
        }
        return currentlyShownComposeViewController
    }
}

// MARK: - Private

extension UIUtils {

    static private func showCompose(composeViewModel: ComposeViewModel) {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: Constants.mainStoryboard, bundle: nil)
            guard
                let composeNavigationController = storyboard.instantiateViewController(withIdentifier:
                                                                                        Constants.composeSceneStoryboardId) as? UINavigationController,
                let composeVc = composeNavigationController.rootViewController
                    as? ComposeViewController
            else {
                Log.shared.errorAndCrash("Missing required data")
                return
            }
            composeVc.viewModel = composeViewModel
            UIUtils.show(navigationController: composeNavigationController)
        }
    }
}
