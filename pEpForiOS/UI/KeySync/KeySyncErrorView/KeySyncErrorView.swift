//
//  KeySyncErrorView.swift
//  pEp
//
//  Created by Alejandro Gelos on 31/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel
import pEpIOSToolbox

struct KeySyncErrorView {
    enum KeySyncErrorAlertAction {
        case notNow, tryAgain
    }

    private init() {}
    
    static public func keySyncErrorView(viewController: UIViewController,
                                        isNewGroup: Bool,
                                        error: Error?,
                                        completion: ((KeySyncErrorResponse) -> ())?) -> PEPAlertViewController? {
        return KeySyncErrorView.errorView(isNewGroup: isNewGroup, completion: { action in
            switch action {
            case .tryAgain:
                dismiss(from: viewController)
                completion?(.tryAgain)
            case .notNow:
                dismiss(from: viewController)
                completion?(.notNow)
            }
        })
    }
}

// MARK: - Private

extension KeySyncErrorView {

    static private func errorView(isNewGroup: Bool,
                                  completion: ((KeySyncErrorAlertAction) -> ())?) -> PEPAlertViewController? {
        let errorTitle = NSLocalizedString("p≡p Sync",
                                           comment: "keySyncWizard animation view title")
        let errorMessage = NSLocalizedString("Something went wrong with syncing the devices. Please try again.",
                                             comment: "keySyncWizard error view message when syncing devices")
        let errorImage = isNewGroup ? #imageLiteral(resourceName: "pEpForiOS-icon-sync-2nd-device") : #imageLiteral(resourceName: "pEpForiOS-icon-sync-3rd-device")

        let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: errorTitle,
                                                  message: errorMessage,
                                                  paintPEPInTitle: true,
                                                  image: [errorImage],
                                                  viewModel: PEPAlertViewModel(alertType: .pEpSyncWizard))

        let errorNotNowTitle = NSLocalizedString("Not now",
                                                 comment: "keySyncWizard error view Not Now button title")
        let errorNotNowAction = PEPUIAlertAction(title: errorNotNowTitle,
                                                 style: .pEpGreyButtonLines,
                                                 handler: { alert in
                                                    completion?(.notNow)
        })

        let errorTryAaginTitle = NSLocalizedString("Try Again",
                                                   comment: "keySyncWizard error view Try Again button title")
        let errorTryAgainAction = PEPUIAlertAction(title: errorTryAaginTitle,
                                                   style: .pEpTextDark,
                                                   handler: { alert in
                                                    completion?(.tryAgain)
        })
        pepAlertViewController?.add(action: errorNotNowAction)
        pepAlertViewController?.add(action: errorTryAgainAction)

        pepAlertViewController?.modalPresentationStyle = .overFullScreen
        pepAlertViewController?.modalTransitionStyle = .crossDissolve

        return pepAlertViewController
    }

    static func dismiss(from viewController: UIViewController) {
        guard let errorView = viewController.presentedViewController else {
            Log.shared.errorAndCrash("pEPSyncError view is not presented")
            return
        }
        DispatchQueue.main.async {
            errorView.dismiss(animated: true)
        }
    }
}
