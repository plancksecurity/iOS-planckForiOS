//
//  UIUtil+Compose.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import PEPIOSToolboxForAppExtensions
#else
import pEpIOSToolbox
#endif

// MARK: - UIUtils+Compose

extension UIUtils {

    static public func showComposeView(from mailto: Mailto?) {
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
            composeVc.viewModel = ComposeViewModel.from(mailTo: mailto)
            UIUtils.show(navigationController: composeNavigationController)
        }
    }
}
