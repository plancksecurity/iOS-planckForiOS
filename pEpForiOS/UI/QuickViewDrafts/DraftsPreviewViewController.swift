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
    public weak var draftsPreviewProtocol: DraftsPreviewProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let childVC = createChildViewController() else {
            Log.shared.errorAndCrash(message: "Child viewController is missing!")
            return
        }
        addChild(childVC)
        childVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        childVC.view.frame = container.bounds
        container.addSubview(childVC.view)

    }

    private func createChildViewController() -> EmailListViewController? {
        let sb = UIStoryboard(name: EmailViewController.storyboard, bundle: nil)
        guard
            let vc = sb.instantiateViewController(
                withIdentifier: EmailListViewController.storyboardId) as? EmailListViewController,
            let folderViewModel = folderVM
            else {
                Log.shared.errorAndCrash("Problem!")
                return nil
        }
        let emailListVM = EmailListViewModel(delegate: vc,
                                             folderToShow: folderViewModel[1][1].folder)
        vc.viewModel = emailListVM
        vc.hidesBottomBarWhenPushed = false

        return vc

    }

// MARK: - IBActions

    @IBAction func composeAction() {
        guard let delegate = draftsPreviewProtocol else {
            Log.shared.errorAndCrash(message: "draftsPreviewDelegate is nil!")
            return
        }
        delegate.composeAction()
    }


    @IBAction func dismissView() {
        dismiss(animated: true)
    }

}

extension DraftsPreviewViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: EmailListViewCell.storyboardId) else {
            Log.shared.errorAndCrash(message: "EmailListViewCell not found!")
            return UITableViewCell()
        }

        return cell
    }

}
