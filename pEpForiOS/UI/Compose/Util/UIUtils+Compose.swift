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

    static public func presentComposeView(from mailto: Mailto? = nil, appConfig: AppConfig) {
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

    private static func composeViewModel(with mailTo: Mailto?) -> ComposeViewModel {
        func identities(addresses: [String]) -> [Identity]? {
            return addresses.map { return Identity(address: $0) }
        }
        var tos: [Identity]? = nil
        if let mailtos = mailTo?.tos {
            tos = identities(addresses: mailtos)
        }
        var ccs: [Identity]? = nil
        if let mailccs = mailTo?.ccs {
            ccs = identities(addresses: mailccs)
        }
        var bccs: [Identity]? = nil
        if let mailbccs = mailTo?.bccs {
            bccs = identities(addresses: mailbccs)
        }
        var initData = ComposeViewModel.InitData(prefilledTos: tos,
                                                 prefilledCCs: ccs,
                                                 prefilledBCCs: bccs)
        if let body = mailTo?.body {
            initData.bodyPlaintext = body
        } else if let firstTo = mailTo?.tos?.first, firstTo == Constants.supportMail {
            /// To give more precise information to Support, we inform the device and OS version.
            let deviceField = NSLocalizedString("Device", comment: "Device field, reporting issue")
            initData.bodyPlaintext = "\n\n\(deviceField): \(UIDevice().type.rawValue)" + "\n" + "OS: \(UIDevice.current.systemVersion)"
            initData.subject = NSLocalizedString("Help", comment: "Contact Support - Mail subject")
        }

        let state = ComposeViewModel.ComposeViewModelState(initData: initData)
        if let subject = mailTo?.subject {
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
