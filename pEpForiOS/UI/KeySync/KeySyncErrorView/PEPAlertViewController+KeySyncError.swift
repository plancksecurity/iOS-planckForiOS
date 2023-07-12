//
//  PlanckAlertViewController+KeySyncError.swift
//  pEp
//
//  Created by Martín Brude on 23/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

extension PlanckAlertViewController {

    /// Retrieves the key sync error popup.
    /// - Parameters:
    ///   - isNewGroup: is it a new group creation or it's joining an existing group
    ///   - completion: The callback to be executed when the user interacts with the error alert view buttons.
    /// - Returns: The configured view controller.
    public static func getKeySyncErrorViewController(isNewGroup: Bool, completion: ((KeySyncErrorResponse) -> ())?) -> PlanckAlertViewController? {
        let errorTitle = NSLocalizedString("planck Sync", comment: "keySyncWizard animation view title")
        let errorMessage = NSLocalizedString("Something went wrong with syncing the devices. Please try again.",
                                             comment: "keySyncWizard error view message when syncing devices")
        let errorImage = isNewGroup ? #imageLiteral(resourceName: "pEpForiOS-icon-sync-2nd-device") : #imageLiteral(resourceName: "pEpForiOS-icon-sync-3rd-device")
        let planckAlertViewController =
            PlanckAlertViewController.fromStoryboard(title: errorTitle,
                                                  message: errorMessage,
                                                  paintPEPInTitle: true,
                                                  image: [errorImage],
                                                  viewModel: PlanckAlertViewModel(alertType: .planckSyncWizard))
        let errorNotNowTitle = NSLocalizedString("Not now",
                                                 comment: "keySyncWizard error view Not Now button title")
        let errorNotNowAction = PlanckUIAlertAction(title: errorNotNowTitle,
                                                    style: .pEpGreyButtonLines,
                                                    handler: { alert in
            completion?(.notNow)
            planckAlertViewController?.dismiss(animated: true)
        })
        let errorTryAaginTitle = NSLocalizedString("Try Again", comment: "keySyncWizard error view Try Again button title")
        var style: UIColor
        style = .label
        let errorTryAgainAction = PlanckUIAlertAction(title: errorTryAaginTitle,
                                                      style: style,
                                                      handler: { alert in
            completion?(.tryAgain)
            planckAlertViewController?.dismiss(animated: true)
        })
        planckAlertViewController?.add(action: errorNotNowAction)
        planckAlertViewController?.add(action: errorTryAgainAction)
        planckAlertViewController?.modalPresentationStyle = .overFullScreen
        planckAlertViewController?.modalTransitionStyle = .crossDissolve

        return planckAlertViewController
    }
}
