//
//  KeySyncWizard.swift
//  pEp
//
//  Created by Alejandro Gelos on 26/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

struct KeySyncWizard {

    enum Action {
        case cancel, decline, accept, leave
    }

    private init() {}

    static func fromStoryboard(meFPR: String,
                               partnerFPR: String,
                               completion: @escaping (KeySyncWizard.Action) -> Void )
        -> PEPPageViewController? {


            let pageViews = wizardViews(meFPR: meFPR, partnerFPR: partnerFPR)
            return PEPPageViewController.fromStoryboard(withViews: pageViews)
    }
}


// MARK: - Private

extension KeySyncWizard {
    static private func wizardViews(meFPR: String, partnerFPR: String) -> [UIViewController] {
        guard let introView = introView(),
            let trustWordsView = trustWordsView(meFPR: meFPR, partnerFPR: partnerFPR),
            let animationView = animationView(),
            let completionView = completionView() else {
                return []
        }

        return [introView, trustWordsView, animationView, completionView]
    }

    static private func introView() -> PEPAlertViewController? {
        let keySyncIntroTitle = NSLocalizedString("p≡p Sync",
                                                  comment: "KeySyncWizard introduction title")
        let keySyncIntroMessage = NSLocalizedString("A second device is detected. Please make sure you have both devices together so you can compare trustwords to sync.",
                                                    comment: "KeySyncWizard introduction message")

        let notNowButtonTitle = NSLocalizedString("Not Now",
                                                  comment: """
                                                              KeySyncIntro view Not Now button
                                                              title
                                                           """)
        let introNotNowAction = PEPUIAlertAction(title: notNowButtonTitle,
                                                 style: .pEpGray,
                                                 handler: { alert in
                                                    //TODO: Ale
        })

        let nextButtonTitle = NSLocalizedString("Next",
                                                comment: "KeySyncIntro view Next button title")
        let introNextAction = PEPUIAlertAction(title: nextButtonTitle,
                                               style: .blue,
                                               handler: { alert in
                                                //TODO: Ale
        })


        let introView = PEPAlertViewController.fromStoryboard(title: keySyncIntroTitle,
                                                              message: keySyncIntroMessage,
                                                              paintPEPInTitle: true,
                                                              image: [#imageLiteral(resourceName: "pEpForiOS-icon-device-detected")])
        introView?.add(action: introNotNowAction)
        introView?.add(action: introNextAction)

        return introView
    }

    static private func trustWordsView(meFPR: String, partnerFPR: String)
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

    static private func animationView() -> PEPAlertViewController? {
        let animatioTitle = NSLocalizedString("p≡p Sync",
                                              comment: "KeySyncAnimation view title")
        let animatioMessage = NSLocalizedString("Please give us a moment while we sync your devices. This can take up to a minute.",
                                                comment: "KeySyncAnimation view message")
        let animatioCancelTitle = NSLocalizedString("Cancel",
                                                    comment: "KeySyncAnimation view cancel button title")
        let animatioCancelAction = PEPUIAlertAction(title: animatioCancelTitle,
                                                    style: .pEpBlue,
                                                    handler: { alert in
                                                        //TODO: Ale
        })

        let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: animatioTitle,
                                                  message: animatioMessage,
                                                  paintPEPInTitle: true,
                                                  image: [#imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-1"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2"), #imageLiteral(resourceName: "pEpForiOS-icon-device-group"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2")])
        pepAlertViewController?.add(action: animatioCancelAction)
        return pepAlertViewController
    }

    static private func completionView() -> PEPAlertViewController? {
        let completionTitle = NSLocalizedString("Device Group",
                                                comment: "keySyncCompletion view title")
        let completionMessage = NSLocalizedString("Your device is now member of your device group.",
                                                  comment: "keySyncCompletion view message")
        let completionLeavelTitle = NSLocalizedString("Leave",
                                                      comment: "keySyncCompletion view leave button title")
        let completionLeavelAction = PEPUIAlertAction(title: completionLeavelTitle,
                                                      style: .pEpRed,
                                                      handler: { alert in
                                                        //TODO: Ale
        })

        let completionOKlTitle = NSLocalizedString("OK",
                                                   comment: "keySyncCompletion view OK button title")
        let completionOKlAction = PEPUIAlertAction(title: completionOKlTitle,
                                                   style: .pEpBlue,
                                                   handler: { alert in
                                                    //TODO: Ale
        })

        let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: completionTitle,
                                                  message: completionMessage,
                                                  paintPEPInTitle: true,
                                                  image: [#imageLiteral(resourceName: "pEpForiOS-icon-device-group")])
        pepAlertViewController?.add(action: completionLeavelAction)
        pepAlertViewController?.add(action: completionOKlAction)
        return pepAlertViewController
    }
}
