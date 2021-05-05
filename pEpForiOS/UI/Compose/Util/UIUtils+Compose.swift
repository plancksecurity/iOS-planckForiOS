//
//  UIUtil+Compose.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

// MARK: - UIUtils+Compose

extension UIUtils {

    static public func showComposeView(from mailto: Mailto?) {
        let viewModel = ComposeViewModel.from(mailTo: mailto)
        showCompose(composeViewModel: viewModel)
    }

    /// Show compose view and prefill the From field with the email address passed by parameter.
    ///
    /// - Parameter address: The email address. It must be valid, otherwise will not present the compose view.
    static public func showComposeView(from address: String) {
        guard String.emailRegex.matchesWhole(string: address) else {
            Log.shared.errorAndCrash("Invalid email address")
            return
        }
        let viewModel = ComposeViewModel.init(prefilledFromAddress: address)
        showCompose(composeViewModel: viewModel)
    }

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

