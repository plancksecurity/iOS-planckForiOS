//
//  Utils+EmailDisplay.swift
//  pEp
//
//  Created by Adam Kowalski on 01/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

// MARK: - UIUtils+EmailDisplay

extension UIUtils {

    /// Push view controller on given navigation controller
    /// - Parameters:
    ///   - navigationController: Navigation controller to use
    ///   - vm: EmailDetailViewModel
    ///   - indexPath: IndexPath is needed to show specified e-mail
    static public func presentEmailDisplayView(navigationController: UINavigationController,
                                               vm: EmailDetailViewModel,
                                               indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
        guard
            let emailDetailVC = storyboard.instantiateViewController(withIdentifier:
                Constants.emailDetailSceneStoryboard) as? EmailDetailViewController
            else {
                Log.shared.errorAndCrash("Missing required data")
                return
        }

        emailDetailVC.viewModel = vm
        emailDetailVC.firstItemToShow = indexPath

        navigationController.pushViewController(emailDetailVC, animated: true)
    }
}
