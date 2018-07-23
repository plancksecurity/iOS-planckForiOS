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
    func showThreadView(sender: EmailListViewModel, for message: Message) -> ThreadedEmailViewModel? {
        let storyboard = UIStoryboard(name: "Thread", bundle: nil)

        guard let singleViewController = getDetailViewController() as? EmailViewController,
            let nav = singleViewController.navigationController,
            let folder = singleViewController.folderShow,
            let vc: ThreadViewController =
            storyboard.instantiateViewController(withIdentifier: "threadViewController")
                as? ThreadViewController
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                return nil
        }
        vc.appConfig = singleViewController.appConfig
        let viewModel = ThreadedEmailViewModel(tip:message, folder: folder)
        viewModel.emailDisplayDelegate = sender
        vc.model = viewModel
        nav.viewControllers[nav.viewControllers.count - 1] = vc
        return viewModel
    }

    func showSingleView(for indexPath: IndexPath) {
        return
    }

    private func getDetailViewController() -> UIViewController? {
        let viewControllers = self.viewControllers
        let last = viewControllers.last

        if isCollapsed {
            guard let nav = last as? UINavigationController,
                let emailNav = nav.topViewController as? UINavigationController,
                let singleViewController = emailNav.rootViewController as? EmailViewController
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return nil
            }
            return singleViewController

        } else {
            guard let nav = last as? UINavigationController,
                let singleViewController = nav.rootViewController as? EmailViewController
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                    return nil
            }
            return singleViewController
        }
    }


}
