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

    static public func presentComposeView(from mailto: Mailto? = nil) {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
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
            present(composeNavigationController: composeNavigationController)
        }
    }
    
    /// Modally presents a "Drafts Preview"
    static public func presentDraftsPreview() {
        let sb = UIStoryboard(name: EmailViewController.storyboard, bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: EmailListViewController.storyboardId) as? EmailListViewController else {
            Log.shared.errorAndCrash("EmailListViewController needed to presentDraftsPreview is not available!")
                return
        }
        let emailListVM = EmailListViewModel(delegate: vc, folderToShow: UnifiedDraft())
        vc.viewModel = emailListVM
        vc.hidesBottomBarWhenPushed = false
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle = .coverVertical
        let navigationController =
            UINavigationController(rootViewController: vc)
        if let toolbar = navigationController.toolbar {
            vc.modalPresentationStyle = .popover
            vc.preferredContentSize = CGSize(width: toolbar.frame.width
                                                - 16,
                                             height: 420)
            vc.popoverPresentationController?.sourceView = vc.view
            let frame = CGRect(x: toolbar.frame.origin.x,
                               y: toolbar.frame.origin.y - 10,
                               width: toolbar.frame.width,
                               height: toolbar.frame.height)
            vc.popoverPresentationController?.sourceRect = frame
        }
        present(composeNavigationController: navigationController)
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
