//
//  PrimarySplitViewcontroller+ScreenComposerProtocol.swift
//  pEp
//
//  Created by Borja González de Pablo on 20/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpUtilities

extension PrimarySplitViewController: ScreenComposerProtocol {
    func emailListViewModel(_ emailListViewModel: EmailListViewModel,
                            requestsShowThreadViewFor message: Message) {
        let storyboard = UIStoryboard(name: "Thread", bundle: nil)

        guard let singleViewController = getDetailViewController() as? EmailViewController else {
            //Do nothing as it is not showing the detail we want
            return
        }

        guard let nav = singleViewController.navigationController,
            let folder = singleViewController.folderShow,
            let vc: ThreadViewController =
            storyboard.instantiateViewController(withIdentifier: "threadViewController")
                as? ThreadViewController
            else {
                Logger.frontendLogger.errorAndCrash("Segue issue")
                return
        }
        vc.appConfig = singleViewController.appConfig
        let viewModel = ThreadedEmailViewModel(tip:message, folder: folder)
        viewModel.emailDisplayDelegate = emailListViewModel
        vc.model = viewModel
        nav.viewControllers[nav.viewControllers.count - 1] = vc
        emailListViewModel.currentDisplayedMessage = viewModel
        emailListViewModel.updateThreadListDelegate = viewModel
    }

    func emailListViewModel(_ emailListViewModel: EmailListViewModel,
                            requestsShowEmailViewFor message: Message) {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let threadViewController = getDetailViewController() as? ThreadViewController else {
            //Do nothing as it is not showing the detail we want
            return
        }
            guard let nav = threadViewController.navigationController,
            let vc: EmailViewController =
            storyboard.instantiateViewController(withIdentifier: "emailDetail")
                as? EmailViewController,
            let index = emailListViewModel.index(of: message)
            else {
                Logger.frontendLogger.errorAndCrash("Segue issues")
                return
        }

        vc.appConfig = threadViewController.appConfig
        vc.message = message
        vc.folderShow = emailListViewModel.folderToShow
        vc.messageId = index
        vc.delegate = emailListViewModel
        emailListViewModel.currentDisplayedMessage = vc
        nav.viewControllers[nav.viewControllers.count - 1 ] = vc
    }

    private func getDetailViewController() -> UIViewController? {
        let viewControllers = self.viewControllers
        let last = viewControllers.last

        if isCollapsed {
            guard let nav = last as? UINavigationController,
                let emailNav = nav.topViewController as? UINavigationController,
                let viewController = emailNav.rootViewController
                else {
                    return nil
            }
            return viewController

        } else {
            guard let nav = last as? UINavigationController,
                let viewController = nav.rootViewController
                else {
                    return nil
            }
            return viewController
        }
    }


}
