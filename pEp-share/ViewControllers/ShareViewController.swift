//
//  ShareViewController.swift
//  pEp-share
//
//  Created by Adam Kowalski on 14/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolboxForExtensions

final class ShareViewController: UIViewController {
    var vm = ShareViewModel()
    var viewBusyState: ViewBusyState?

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
        case noAccount
        case userCanceled
        case messageCouldNotBeSaved
    }

    func startComposeView(composeViewModel: ComposeViewModel) {
        presentComposeVC(composeViewModel: composeViewModel)
    }

    func outgoingMessageCouldNotBeSaved() {
        extensionContext?.cancelRequest(withError: SharingError.messageCouldNotBeSaved)
    }

    func canceledByUser() {
        extensionContext?.cancelRequest(withError: SharingError.userCanceled)
    }

    func messageSent(error: Error?) {
        if let theViewBusyState = viewBusyState {
            view.stopDisplayingAsBusy(viewBusyState: theViewBusyState)
            viewBusyState = nil
        }

        if let theError = error {
            let title = NSLocalizedString("Error", comment: "Sharing extension error title")
            let message = NSLocalizedString("Message could not be sent",
                                            comment: "Sharing extension message send error")
            func cancelRequest() {
                extensionContext?.cancelRequest(withError: theError)
            }
            UIUtils.showAlertWithOnlyPositiveButton(title: title,
                                                    message: message,
                                                    completion: cancelRequest)
        } else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    func noAccount() {
        extensionContext?.cancelRequest(withError: SharingError.noAccount)
    }

    func messageIsBeingSent() {
        if let theView = navigationController?.view {
            viewBusyState = theView.displayAsBusy()
        }
    }
}

// MARK: - Private Extension

extension ShareViewController {
    private func presentComposeVC(composeViewModel: ComposeViewModel) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let composeVC = storyboard.instantiateViewController(withIdentifier: ComposeViewController.storyboardId) as? ComposeViewController else {
            Log.shared.errorAndCrash("Cannot instantiate ComposeViewController")
            return
        }

        composeVC.viewModel = composeViewModel

        navigationController?.pushViewController(composeVC, animated: false)
    }
}
