//
//  PEPAlertViewController+KeySyncError.swift
//  pEp
//
//  Created by Martín Brude on 23/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension PEPAlertViewController {

    /// Retrieves the key sync error popup.
    /// - Parameters:
    ///   - isNewGroup: is it a new group creation or it's joining an existing group
    ///   - completion: The callback to be executed when the user interacts with the error alert view buttons.
    /// - Returns: The configured view controller.
    public static func getKeySyncErrorViewController(isNewGroup: Bool, completion: ((KeySyncErrorResponse) -> ())?) -> PEPAlertViewController? {
        let errorTitle = NSLocalizedString("p≡p Sync", comment: "keySyncWizard animation view title")
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
                                                    pepAlertViewController?.dismiss(animated: true)
        })
        let errorTryAaginTitle = NSLocalizedString("Try Again", comment: "keySyncWizard error view Try Again button title")
        let errorTryAgainAction = PEPUIAlertAction(title: errorTryAaginTitle,
                                                   style: .pEpTextDark,
                                                   handler: { alert in
                                                    completion?(.tryAgain)
                                                    pepAlertViewController?.dismiss(animated: true)
        })
        pepAlertViewController?.add(action: errorNotNowAction)
        pepAlertViewController?.add(action: errorTryAgainAction)
        pepAlertViewController?.modalPresentationStyle = .overFullScreen
        pepAlertViewController?.modalTransitionStyle = .crossDissolve

        return pepAlertViewController
    }
}
