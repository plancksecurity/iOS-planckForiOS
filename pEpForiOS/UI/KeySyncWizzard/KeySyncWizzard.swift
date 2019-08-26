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
                                                                     image: [#imageLiteral(resourceName: "DeviceGroup-animation-3")])
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

//    private func keySyncAnimationView() -> PEPAlertViewController? {
//        let keySyncAnimatioTitle = NSLocalizedString("p≡p Sync",
//                                                  comment: "KeySyncAnimation view title")
//        let keySyncAnimatioMessage = NSLocalizedString("Please give us a moment while we sync your devices. This can take up to a minute.",
//                                                    comment: "KeySyncAnimation view message")
//        return PEPAlertViewController.fromStoryboard(title: keySyncIntroTitle,
//                                                     message: keySyncIntroMessage,
//                                                     paintPEPInTitle: true,
//                                                     image: [#imageLiteral(resourceName: "DeviceGroup-animation-3")])
//    }
}
