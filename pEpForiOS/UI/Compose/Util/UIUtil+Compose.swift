//
//  UIUtil+Compose.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

// MARK: - UIUtil+Compose

extension UIUtils {

    /// Modally presents a "Compose New Mail" view.
    /// If we can parse a recipient from the url (e.g. "mailto:me@me.com") we prefill the "To:"
    /// field of the presented compose view.
    ///
    /// - Parameters:
    ///   - url: url to parse recipients from
    static public func presentComposeView(forRecipientInUrl url: URL? = nil) {
        let address = url?.firstRecipientAddress()
        if url != nil && address == nil {
            // A URL has been passed, but it is no valid mailto URL.
            return
        }

        presentComposeView(forRecipientWithAddress: address)
    }

    /// Modally presents a "Compose New Mail" view.
    /// If we can parse a recipient from the url (e.g. "mailto:me@me.com") we prefill the "To:"
    /// field of the presented compose view.
    ///
    /// - Parameters:
    ///   - address: address to prefill "To:" field with
    static public func presentComposeView(forRecipientWithAddress address: String?) {
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
        if address == Constants.supportMail {
            composeVc.viewModel = composeViewModelForSupport()
        } else {
            composeVc.viewModel = composeViewModel(forRecipientWithAddress: address)
        }
        present(composeNavigationController: composeNavigationController)
    }

    /// Modally presents a "Drafts Preview"
    static public func presentDraftsPreview() {
        let sb = UIStoryboard(name: EmailViewController.storyboard, bundle: nil)
        guard
            let vc = sb.instantiateViewController(
                withIdentifier: EmailListViewController.storyboardId) as? EmailListViewController else {
                Log.shared.errorAndCrash("EmailListViewController needed to presentDraftsPreview is not available!")
                return
        }

        let emailListVM = EmailListViewModel(delegate: vc,
                                             folderToShow: UnifiedDraft())
        vc.viewModel = emailListVM
        vc.hidesBottomBarWhenPushed = false
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle = .coverVertical

        let navigationController = UINavigationController(rootViewController: vc)
        if let toolbar = navigationController.toolbar {
            vc.modalPresentationStyle = .popover
            vc.preferredContentSize = CGSize(width: toolbar.frame.width - 16,
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

    // MARK: - Private - ComposeViewModel

    private static func composeViewModelForSupport() -> ComposeViewModel {
        let mail = Constants.supportMail
        guard let url = URL(string:"mailto:\(mail)"),
            let address = url.firstRecipientAddress() else {
            Log.shared.errorAndCrash("Mail not found")
            return ComposeViewModel()
        }
        let to = Identity(address: address)
        var initData = ComposeViewModel.InitData(withPrefilledToRecipient: to, composeMode: .normal)
        let deviceField = NSLocalizedString("Device", comment: "Device field, reporting issue")
        initData.bodyPlaintext = "\n\n\(deviceField): \(UIDevice().type.rawValue)" + "\n" + "OS: \(UIDevice.current.systemVersion)"
        let state = ComposeViewModel.ComposeViewModelState(initData: initData)
        state.subject = NSLocalizedString("Help", comment: "Contact Support - Mail subject") 
        return ComposeViewModel(state: state)
    }

    private static func composeViewModel(forRecipientWithAddress address: String?) -> ComposeViewModel {
        var prefilledTo: Identity? = nil
        if let address = address {
            let to = Identity(address: address)
            to.session.commit()
            prefilledTo = to
        }
        return ComposeViewModel(composeMode: .normal, prefilledTo: prefilledTo)
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
