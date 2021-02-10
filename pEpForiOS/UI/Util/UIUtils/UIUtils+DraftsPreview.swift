//
//  UIUtils+DraftsPreview.swift
//  pEp
//
//  Created by Dirk Zimmermann on 10.02.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UIUtils {
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
        UIUtils.show(navigationController: navigationController)
    }
}
