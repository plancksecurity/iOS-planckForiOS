//
//  KeySyncWizzard.swift
//  pEp
//
//  Created by Alejandro Gelos on 26/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

struct KeySyncWizzard {

//    static func fromStoryboard() -> WizzardPageViewController {
////        let introductionView = PEPAlertViewController.fromStoryboard(title: <#T##String?#>, message: <#T##String?#>, paintPEPInTitle: <#T##Bool#>, image: <#T##[UIImage]?#>, viewModel: <#T##PEPAlertViewModelProtocol#>)
//
//
////        return WizzardPageViewController.fromStoryboard(withViews: <#T##[UIViewController]#>)
//    }
}


// MARK: - Private

extension KeySyncWizzard {
//    private func wizzardViews(meFPR: String, partnerFPR: String) -> [PEPAlertViewController] {
//
//    }

    private func introView() -> PEPAlertViewController? {
        let keySyncIntroTitle = NSLocalizedString("p≡p Sync",
                                                  comment: "KeySyncWizzard introduction title")
        let keySyncIntroMessage = NSLocalizedString("A second device is detected. Please make sure you have both devices together so you can compare trustwords to sync.",
                                                    comment: "KeySyncWizzard introduction message")
        return PEPAlertViewController.fromStoryboard(title: keySyncIntroTitle,
                                                     message: keySyncIntroMessage,
                                                     paintPEPInTitle: true,
                                                     image: [#imageLiteral(resourceName: "pEpForiOS-icon-device-detected")])
    }

    private func trustWordsView(meFPR: String, partnerFPR: String)
        -> KeySyncHandshakeViewController? {
            let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
            guard let handShakeViewController = storyboard.instantiateViewController(
                withIdentifier: KeySyncHandshakeViewController.storyboardId) as? KeySyncHandshakeViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController KeySyncHandshakeViewController")
                    return nil
            }
            handShakeViewController.completionHandler { action in
                //TODO: Ale
            }

            handShakeViewController.finderPrints(meFPR: meFPR, partnerFPR: partnerFPR)

            return handShakeViewController
    }

    private func keySyncAnimationView() -> PEPAlertViewController? {
        let keySyncAnimatioTitle = NSLocalizedString("p≡p Sync",
                                                     comment: "KeySyncAnimation view title")
        let keySyncAnimatioMessage = NSLocalizedString("Please give us a moment while we sync your devices. This can take up to a minute.",
                                                       comment: "KeySyncAnimation view message")
        let keySyncAnimatioCancelTitle = NSLocalizedString("Cancel",
                                                           comment: "KeySyncAnimation view cancel button title")
        let keySyncAnimatioCancelAction = PEPUIAlertAction(title: keySyncAnimatioCancelTitle,
                                                           style: .pEpBlue,
                                                           handler: { alert in
                                                            //TODO: Ale
        })

        let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: keySyncAnimatioTitle,
                                                  message: keySyncAnimatioMessage,
                                                  paintPEPInTitle: true,
                                                  image: [#imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-1"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2"), #imageLiteral(resourceName: "pEpForiOS-icon-device-group"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2")])
        pepAlertViewController?.add(action: keySyncAnimatioCancelAction)
        return pepAlertViewController
    }

    private func keySyncCompletionView() -> PEPAlertViewController? {
        let keySyncAnimatioTitle = NSLocalizedString("Device Group",
                                                     comment: "keySyncCompletion view title")
        let keySyncAnimatioMessage = NSLocalizedString("Your device is now member of your device group.",
                                                       comment: "keySyncCompletion view message")
        let keySyncAnimatioLeavelTitle = NSLocalizedString("Leave",
                                                           comment: "keySyncCompletion view leave button title")
        let keySyncAnimatioLeavelAction = PEPUIAlertAction(title: keySyncAnimatioLeavelTitle,
                                                           style: .pEpRed,
                                                           handler: { alert in
                                                            //TODO: Ale
        })

        let keySyncAnimatioOKlTitle = NSLocalizedString("OK",
                                                           comment: "keySyncCompletion view OK button title")
        let keySyncAnimatioOKlAction = PEPUIAlertAction(title: keySyncAnimatioOKlTitle,
                                                           style: .pEpBlue,
                                                           handler: { alert in
                                                            //TODO: Ale
        })

        let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: keySyncAnimatioTitle,
                                                  message: keySyncAnimatioMessage,
                                                  paintPEPInTitle: true,
                                                  image: [#imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-1"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2"), #imageLiteral(resourceName: "pEpForiOS-icon-device-group"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2")])
        pepAlertViewController?.add(action: keySyncAnimatioLeavelAction)
        pepAlertViewController?.add(action: keySyncAnimatioOKlAction)
        return pepAlertViewController
    }
}
