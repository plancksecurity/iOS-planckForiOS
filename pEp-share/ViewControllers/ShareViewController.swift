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

// MARK: - Private ShareViewModelDelegate and Helpers

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
        func cancelRequest() {
            extensionContext?.cancelRequest(withError: SharingError.messageCouldNotBeSaved)
        }

        let title = NSLocalizedString("Error", comment: "Sharing extension error title")
        let message = NSLocalizedString("Could not save the message for sending",
                                        comment: "Sharing extension could not save a message")
        UIUtils.showAlertWithOnlyPositiveButton(title: title,
                                                message: message,
                                                completion: cancelRequest)
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
            extensionContext?.cancelRequest(withError: theError)
        } else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    func noAccount() {
        func cancelRequest() {
            extensionContext?.cancelRequest(withError: SharingError.noAccount)
        }

        let title = NSLocalizedString("Error", comment: "Sharing extension error title")
        let message = NSLocalizedString("No Account found",
                                        comment: "Sharing extension has no account")
        UIUtils.showAlertWithOnlyPositiveButton(title: title,
                                                message: message,
                                                completion: cancelRequest)
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
