//
//  UIUtil+Compose.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

// MARK: - UIUtils+Compose

extension UIUtils {

    static public func presentComposeView(from mailto: Mailto? = nil, appConfig: AppConfig) {
        DispatchQueue.main.async {
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
            composeVc.viewModel = ComposeViewModel.from(mailTo: mailto)
            composeVc.appConfig = appConfig
            present(composeNavigationController: composeNavigationController)
        }
    }

    // MARK: - Private - Present

    private static func present(composeNavigationController: UINavigationController) {
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        presenterVc.present(composeNavigationController, animated: true)
    }
}
