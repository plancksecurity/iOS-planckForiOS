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

    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - Private ShareViewModelDelegate

extension ShareViewController: ShareViewModelDelegate {
    func startComposeView(sharedTypes: [SharedType]) {
        presentComposeVC(sharedTypes: sharedTypes)
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

        let bodyHtml = NSAttributedString(string: "This has been shared")
        let initData = ComposeViewModel.InitData(subject: "Shared",
                                                 bodyHtml: bodyHtml,
                                                 inlinedAttachments: [],
                                                 nonInlinedAttachments: [])

        let composeVMState = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        let composeViewModel = ComposeViewModel(state: composeVMState)
        composeVC.viewModel = composeViewModel

        present(composeVC, animated: true, completion: nil)
    }
}
