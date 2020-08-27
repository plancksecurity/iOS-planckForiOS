//
//  QuickViewDraftsViewController.swift
//  pEp
//
//  Created by Adam Kowalski on 15/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

final class DraftsPreviewViewController: UIViewController {

    static let storyboardId = "QuickViewDrafts"

    @IBOutlet weak var container: UIView!

    public var folderVM: FolderViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let childVC = createEmailListViewController() else {
            Log.shared.errorAndCrash(message: "Child viewController is missing!")
            return
        }
        addChild(childVC)
        childVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        childVC.view.frame = container.bounds
        container.addSubview(childVC.view)

    }

    private func createEmailListViewController() -> EmailListViewController? {
        let sb = UIStoryboard(name: EmailViewController.storyboard, bundle: nil)
        guard
            let vc = sb.instantiateViewController(
                withIdentifier: EmailListViewController.storyboardId) as? EmailListViewController,
            let folderViewModel = folderVM else {
                Log.shared.errorAndCrash("Problem!")
                return nil
        }

        guard let draftsIndex = FolderType.displayOrder.firstIndex(where: { $0 == .drafts }) else {
            Log.shared.errorAndCrash(message: "Drafts index is missing!")
            return nil
        }

        guard let firstSection = folderViewModel.items.first else {
            Log.shared.errorAndCrash(message: "First section was not found!")
            return nil
        }

        let emailListVM = EmailListViewModel(delegate: vc,
                                             folderToShow: firstSection[draftsIndex].folder)
        vc.viewModel = emailListVM
        vc.hidesBottomBarWhenPushed = false

        return vc
    }

// MARK: - IBActions

    @IBAction func composeAction() {

        dismiss(animated: true) {
            UIUtils.presentComposeView()
        }
    }

    @IBAction func dismissView() {
        dismiss(animated: true)
    }

}
