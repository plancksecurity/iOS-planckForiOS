//
//  PrimarySplitViewcontroller+ScreenComposerProtocol.swift
//  pEp
//
//  Created by Borja González de Pablo on 20/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension PrimarySplitViewController: ScreenComposerProtocol{
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
                Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
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
                as? EmailViewController
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                return
        }

        vc.appConfig = threadViewController.appConfig
        nav.viewControllers[nav.viewControllers.count - 1 ] = vc
        emailListViewModel.currentDisplayedMessage = vc

    }

    private func getDetailViewController() -> UIViewController? {
        let viewControllers = self.viewControllers
        let last = viewControllers.last

        if isCollapsed {
            guard let nav = last as? UINavigationController,
                let emailNav = nav.topViewController as? UINavigationController,
                let viewController = emailNav.rootViewController as? EmailViewController
                else {
                    return nil
            }
            return viewController

        } else {
            guard let nav = last as? UINavigationController,
                let viewController = nav.rootViewController as? EmailViewController
                else {
                    return nil
            }
            return viewController
        }
    }


}
