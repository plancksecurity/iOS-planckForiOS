//
//  UIUtils+PresentVC.swift
//  pEp
//
//  Created by Adam Kowalski on 15/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UIUtils {

    static public func presentDraftsQuickView() {
        guard let vc = UIStoryboard.init(name: QuickViewDraftsViewController.storyboardId, bundle: Bundle.main).instantiateViewController(withIdentifier: "QuickViewDraftsViewController") as? QuickViewDraftsViewController else {
            Log.shared.errorAndCrash("No controller")
            return
        }
        guard let presenterVc = UIApplication.currentlyVisibleViewController() else {
            Log.shared.errorAndCrash("No VC")
            return
        }
        vc.modalPresentationStyle = .pageSheet
        vc.title = "Drafts" // TODO: ak - add translations or move to Storyboard
        vc.setToolbarItems([UIBarButtonItem(title: "Cancel", style: .done, target: self, action: nil)], animated: true)
//        let navigationController = UINavigationController()
//        navigationController.setViewControllers([vc], animated: true)
        presenterVc.present(vc, animated: true)
    }


}
