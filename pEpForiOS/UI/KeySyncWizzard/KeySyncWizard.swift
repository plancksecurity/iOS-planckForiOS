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
        case cancel, decline, accept
    }

    private init() {}

    static func fromStoryboard(meFPR: String,
                               partnerFPR: String,
                               keySyncDeviceGroupService:
        KeySyncDeviceGroupServiceProtocol = KeySyncDeviceGroupService(),
                               completion: @escaping (KeySyncWizard.Action) -> Void )
        -> PEPPageViewController? {

            guard let pEpPageViewController = PEPPageViewController.fromStoryboard() else {
                return nil
            }
            let pageViews = wizardViews(page: pEpPageViewController,
                                        pageCompletion: completion,
                                        meFPR: meFPR,
                                        partnerFPR: partnerFPR,
                                        keySyncDeviceGroupService: keySyncDeviceGroupService)
            pEpPageViewController.views = pageViews
            return pEpPageViewController
    }
}


// MARK: - Private

extension KeySyncWizard {
    static private func wizardViews(page: PEPPageViewController,
                                    pageCompletion: @escaping (KeySyncWizard.Action) -> Void,
                                    meFPR: String,
                                    partnerFPR: String,
                                    keySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol)
        -> [UIViewController] {

            guard let introView = introView(page: page, pageCompletion: pageCompletion),
                let trustWordsView = trustWordsView(meFPR: meFPR,
                                                    partnerFPR: partnerFPR,
                                                    page: page,
                                                    pageCompletion: pageCompletion),
                let animationView = animationView(page: page, pageCompletion: pageCompletion),
                let completionView = completionView(page: page,
                                                    keySyncDeviceGroupService: keySyncDeviceGroupService,
                                                    pageCompletion: pageCompletion) else {
                    return []
            }

            return [introView, trustWordsView, animationView, completionView]
    }

    static private func introView(page: PEPPageViewController,
                                  pageCompletion: @escaping (KeySyncWizard.Action) -> Void)
        -> PEPAlertViewController? {

            let keySyncIntroTitle = NSLocalizedString("p≡p Sync",
                                                      comment: "KeySyncWizard introduction title")
            let keySyncIntroMessage = NSLocalizedString("A second device is detected. Please make sure you have both devices together so you can compare trustwords to sync.",
                                                        comment: "KeySyncWizard introduction message")

            guard let introView = PEPAlertViewController.fromStoryboard(title: keySyncIntroTitle,
                                                                        message: keySyncIntroMessage,
                                                                        paintPEPInTitle: true,
                                                                        image: [#imageLiteral(resourceName: "pEpForiOS-icon-device-detected")]) else {
                                                                            return nil
            }

            let notNowButtonTitle = NSLocalizedString("Not Now",
                                                      comment: "KeySyncIntro view Not Now button title")
            let introNotNowAction = PEPUIAlertAction(title: notNowButtonTitle,
                                                     style: .pEpGray,
                                                     handler: { [weak page] alert in
                                                        pageCompletion(.cancel)
                                                        page?.dismiss()


            })

            let nextButtonTitle = NSLocalizedString("Next",
                                                    comment: "KeySyncIntro view Next button title")
            let introNextAction = PEPUIAlertAction(title: nextButtonTitle,
                                                   style: .pEpBlue,
                                                   handler: { [weak page] alert in
                                                    page?.goToNextView()
            })

            introView.add(action: introNotNowAction)
            introView.add(action: introNextAction)

            return introView
    }

    static private func trustWordsView(meFPR: String,
                                       partnerFPR: String,
                                       page: PEPPageViewController,
                                       pageCompletion: @escaping (KeySyncWizard.Action) -> Void)
        -> KeySyncHandshakeViewController? {
            let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
            guard let handShakeViewController = storyboard.instantiateViewController(
                withIdentifier: KeySyncHandshakeViewController.storyboardId) as? KeySyncHandshakeViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController KeySyncHandshakeViewController")
                    return nil
            }
            handShakeViewController.completionHandler { [weak page] action in
                switch action {
                case .accept:
                    pageCompletion(.accept)
                    page?.goToNextView()
                case .cancel:
                    pageCompletion(.cancel)
                    page?.dismiss()
                case .decline:
                    pageCompletion(.decline)
                    page?.dismiss()
                }
            }

            handShakeViewController.finderPrints(meFPR: meFPR, partnerFPR: partnerFPR)

            return handShakeViewController
    }

    static private func animationView(page: PEPPageViewController,
                                      pageCompletion: @escaping (KeySyncWizard.Action) -> Void)
        -> PEPAlertViewController? {
            let animatioTitle = NSLocalizedString("p≡p Sync",
                                                  comment: "KeySyncAnimation view title")
            let animatioMessage = NSLocalizedString("Please give us a moment while we sync your devices. This can take up to a minute.",
                                                    comment: "KeySyncAnimation view message")

            let pepAlertViewController =
                PEPAlertViewController.fromStoryboard(title: animatioTitle,
                                                      message: animatioMessage,
                                                      paintPEPInTitle: true,
                                                      image: [#imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-1"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2"), #imageLiteral(resourceName: "pEpForiOS-icon-device-group"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2")])

            let animatioCanceButtonlTitle = NSLocalizedString("Cancel",
                                                              comment: "KeySyncAnimation view cancel button title")
            let animatioCancelAction = PEPUIAlertAction(title: animatioCanceButtonlTitle,
                                                        style: .pEpBlue,
                                                        handler: { [weak page] alert in
                                                            pageCompletion(.cancel)
                                                            page?.dismiss()
            })
            pepAlertViewController?.add(action: animatioCancelAction)
            return pepAlertViewController
    }

    static private func completionView(page: PEPPageViewController,
                                       keySyncDeviceGroupService: KeySyncDeviceGroupServiceProtocol,
                                       pageCompletion: @escaping (KeySyncWizard.Action) -> Void)
        -> PEPAlertViewController? {
            let completionTitle = NSLocalizedString("Device Group",
                                                    comment: "keySyncCompletion view title")
            let completionMessage = NSLocalizedString("Your device is now member of your device group.",
                                                      comment: "keySyncCompletion view message")

            let pepAlertViewController =
                PEPAlertViewController.fromStoryboard(title: completionTitle,
                                                      message: completionMessage,
                                                      paintPEPInTitle: true,
                                                      image: [#imageLiteral(resourceName: "pEpForiOS-icon-device-group")])

            let completionLeavelTitle = NSLocalizedString("Leave",
                                                          comment: "keySyncCompletion view leave button title")
            let completionLeavelAction = PEPUIAlertAction(title: completionLeavelTitle,
                                                          style: .pEpRed,
                                                          handler: { [weak page] alert in
                                                            leaveDeviceGroup(keySyncDeviceGroupService)
                                                            page?.dismiss()
            })

            let completionOKlTitle = NSLocalizedString("OK",
                                                       comment: "keySyncCompletion view OK button title")
            let completionOKlAction = PEPUIAlertAction(title: completionOKlTitle,
                                                       style: .pEpBlue,
                                                       handler: { [weak page] alert in
                                                        page?.dismiss()
            })
            pepAlertViewController?.add(action: completionLeavelAction)
            pepAlertViewController?.add(action: completionOKlAction)
            return pepAlertViewController
    }
}


// MARK: - Private

extension KeySyncWizard {
    private static func leaveDeviceGroup(_ keySyncDeviceGroupService:
        KeySyncDeviceGroupServiceProtocol) {
        do {
            try keySyncDeviceGroupService.leaveDeviceGroup()
        } catch {
            Log.shared.errorAndCrash("%@", error.localizedDescription)
        }
    }
}
