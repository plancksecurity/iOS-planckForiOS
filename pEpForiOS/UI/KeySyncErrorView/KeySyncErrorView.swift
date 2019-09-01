//
//  KeySyncErrorView.swift
//  pEp
//
//  Created by Alejandro Gelos on 31/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit
import MessageModel

struct KeySyncErrorView {
    enum KeySyncErrorAlertAction {
        case notNow, tryAgain
    }

    private init() {}

    static func presentKeySyncError(viewController: UIViewController,
                             error: Error?,
                             completion: ((KeySyncErrorResponse) -> ())?) {
        guard let keySyncErrorView = KeySyncErrorView.errorView(completion: {
            action in
            switch action {
            case .tryAgain:
                completion?(.tryAgain)
                dismiss(from: viewController)
            case .notNow:
                completion?(.notNow)
                dismiss(from: viewController)
            }
        }) else {
            return
        }

        DispatchQueue.main.async { [weak viewController] in
            guard let viewController = viewController else {
                Log.shared.errorAndCrash("Lost viewController, to present KeySyncError view")
                return
            }

            if let presentedViewController = viewController.presentedViewController {
                presentedViewController.dismiss(animated: true) {
                    viewController.present(keySyncErrorView, animated: true, completion: nil)
                }
            } else {
                viewController.present(keySyncErrorView, animated: true, completion: nil)
            }
        }
    }
}


// MARK: - Private

extension KeySyncErrorView {

    static private func errorView(completion: ((KeySyncErrorAlertAction) -> ())?)
        -> PEPAlertViewController? {
            let errorTitle = NSLocalizedString("p≡p Sync", comment: "keySyncWizard animation view title")
            let errorMessage = NSLocalizedString("Something went wrong with syncing the devices. Please try again.",
                                                 comment: "keySyncWizard error view message")

            let pepAlertViewController =
                PEPAlertViewController.fromStoryboard(title: errorTitle,
                                                      message: errorMessage,
                                                      paintPEPInTitle: true,
                                                      image: [#imageLiteral(resourceName: "pEpForiOS-icon-device-detected")])

            let errorNotNowTitle = NSLocalizedString("Not now",
                                                     comment: "keySyncWizard error view NotNow button title")
            let errorNotNowAction = PEPUIAlertAction(title: errorNotNowTitle,
                                                     style: .pEpGray,
                                                     handler: { alert in
                                                        completion?(.notNow)
            })

            let errorTryAaginTitle = NSLocalizedString("Try Again",
                                                       comment: "keySyncWizard error view Try Again button title")
            let errorTryAaginAction = PEPUIAlertAction(title: errorTryAaginTitle,
                                                       style: .pEpBlue,
                                                       handler: { alert in
                                                        completion?(.tryAgain)

            })
            pepAlertViewController?.add(action: errorNotNowAction)
            pepAlertViewController?.add(action: errorTryAaginAction)

            pepAlertViewController?.modalPresentationStyle = .overFullScreen
            pepAlertViewController?.modalTransitionStyle = .crossDissolve

            return pepAlertViewController
    }

    static func dismiss(from viewController: UIViewController) {
        DispatchQueue.main.async { [weak viewController] in
            viewController?.dismiss(animated: true, completion: nil)
        }
    }
}
