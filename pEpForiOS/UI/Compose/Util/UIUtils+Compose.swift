//
//  UIUtil+Compose.swift
//  pEp
//
//  Created by Andreas Buff on 13.03.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - UIUtil+Compose

import MessageModel

extension UIUtils {

    static public func presentComposeView(from mailto: Mailto, appConfig: AppConfig) {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
            guard
                let composeNavigationController = storyboard.instantiateViewController(withIdentifier:
                    Constants.composeSceneStoryboardId) as? UINavigationController,
                let composeVc = composeNavigationController.rootViewController
                    as? ComposeTableViewController
                else {
                    Log.shared.errorAndCrash("Missing required data")
                    return
            }
            composeVc.viewModel = composeViewModel(with: mailto)
            composeVc.appConfig = appConfig
            present(composeNavigationController: composeNavigationController)
        }
    }

    /// Modally presents a "Compose New Mail" view.
    /// If we can parse a recipient from the url (e.g. "mailto:me@me.com") we prefill the "To:"
    /// field of the presented compose view.
    ///
    /// - Parameters:
    ///   - url: url to parse recipients from
    ///   - appConfig: AppConfig to forward
    static public func presentComposeView(forRecipientInUrl url: URL?,
                                   appConfig: AppConfig) {
        let address = url?.firstRecipientAddress()
        if url != nil && address == nil {
            // A URL has been passed, but it is no valid mailto URL.
            return
        }

        presentComposeView(forRecipientWithAddress: address,
                           appConfig: appConfig)
    }

    /// Modally presents a "Compose New Mail" view.
    /// If we can parse a recipient from the url (e.g. "mailto:me@me.com") we prefill the "To:"
    /// field of the presented compose view.
    ///
    /// - Parameters:
    ///   - address: address to prefill "To:" field with
    ///   - viewController: presenting view controller
    ///   - appConfig: AppConfig to forward
    static public func presentComposeView(forRecipientWithAddress address: String?,
                                   appConfig: AppConfig) {
        let storyboard = UIStoryboard(name: Constants.composeSceneStoryboard, bundle: nil)
        guard
            let composeNavigationController = storyboard.instantiateViewController(withIdentifier:
                Constants.composeSceneStoryboardId) as? UINavigationController,
            let composeVc = composeNavigationController.rootViewController
                as? ComposeTableViewController
            else {
                Log.shared.errorAndCrash("Missing required data")
                return
        }
        if address == Constants.supportMail {
            composeVc.viewModel = composeViewModelForSupport()
        } else {
            composeVc.viewModel = composeViewModel(forRecipientWithAddress: address)
        }
        composeVc.appConfig = appConfig
        present(composeNavigationController: composeNavigationController)
    }

    // MARK: - Private - ComposeViewModel

    private static func composeViewModelForSupport() -> ComposeViewModel {
        let mail = Constants.supportMail
        guard let url = URL(string:"mailto:\(mail)"),
            let address = url.firstRecipientAddress() else {
            Log.shared.errorAndCrash("Mail not found")
            return ComposeViewModel()
        }
        var prefilledTo: Identity? = nil
        let to = Identity(address: address)
        to.save()
        prefilledTo = to
        var initData = ComposeViewModel.InitData(withPrefilledToRecipient: prefilledTo, composeMode: .normal)
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
            to.save()
            prefilledTo = to
        }
        return ComposeViewModel(composeMode: .normal, prefilledTo: prefilledTo)
    }

    private static func composeViewModel(with mailTo: Mailto) -> ComposeViewModel {
        func identities(addresses: [String]) -> [Identity]? {
            return addresses.map { return Identity(address: $0) }
        }
        var tos: [Identity]? = nil
        if let mailtos = mailTo.tos {
            tos = identities(addresses: mailtos)
        }
        var ccs: [Identity]? = nil
        if let mailccs = mailTo.ccs {
            ccs = identities(addresses: mailccs)
        }
        var bccs: [Identity]? = nil
        if let mailbccs = mailTo.bccs {
            bccs = identities(addresses: mailbccs)
        }
        var initData = ComposeViewModel.InitData(prefilledTos: tos,
                                                 prefilledCCs: ccs,
                                                 prefilledBCCs: bccs)
        if let body = mailTo.body {
            initData.bodyPlaintext = body
        }
        let state = ComposeViewModel.ComposeViewModelState(initData: initData)
        if let subject = mailTo.subject {
            state.subject = subject
        }
        return ComposeViewModel(state: state)
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
