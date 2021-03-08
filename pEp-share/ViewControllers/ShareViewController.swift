//
//  ShareViewController.swift
//  pEp-share
//
//  Created by Adam Kowalski on 14/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import PEPIOSToolboxForAppExtensions

final class ShareViewController: UIViewController {
    var vm = ShareViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let context = extensionContext else {
            Log.shared.errorAndCrash(message: "Lost extension context!")
            return
        }

        vm.shareViewModelDelegate = self
        vm.loadInputItems(extensionContext: context)
    }
}

// MARK: - Private ShareViewModelDelegate

extension ShareViewController: ShareViewModelDelegate {
    /// The possible errors this extension can give to the hosting app.
    enum SharingError: Error {
        case userCanceled
    }

    func startComposeView(sharedTypes: [SharedType]) {
        presentComposeVC(sharedTypes: sharedTypes)
    }

    func outgoingMessageCouldNotBeSaved() {
        // TODO
    }

    func canceledByUser() {
        extensionContext?.cancelRequest(withError: SharingError.userCanceled)
    }
}

// MARK: - Private Extension

extension ShareViewController {
    private func presentComposeVC(sharedTypes: [SharedType]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let composeVC = storyboard.instantiateViewController(withIdentifier: ComposeViewController.storyboardId) as? ComposeViewController else {
            Log.shared.errorAndCrash("Cannot instantiate ComposeViewController")
            return
        }

        let composeVM = vm.composeViewModel(sharedTypes: sharedTypes)
        composeVC.viewModel = composeVM

        navigationController?.pushViewController(composeVC, animated: false)
    }
}
