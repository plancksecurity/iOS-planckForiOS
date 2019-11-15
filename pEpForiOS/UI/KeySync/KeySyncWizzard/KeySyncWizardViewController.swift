//
//  KeySyncWizardViewController.swift
//  pEp
//
//  Created by Andreas Buff on 15.11.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

extension KeySyncWizardViewController {

    enum Action {
        case cancel
        case decline
        case accept
    }
}

final class KeySyncWizardViewController: PEPPageViewControllerBase {
    static let storyboardId = "KeySyncWizardViewController"

    /// All the `init`s exist soley to be able to set the transitionStyle.
    override init(transitionStyle: UIPageViewController.TransitionStyle,
                  navigationOrientation: UIPageViewController.NavigationOrientation,
                  options: [UIPageViewController.OptionsKey : Any]?) {
        super.init(transitionStyle: .scroll ,
                   navigationOrientation: navigationOrientation,
                   options: options)
    }

    /// All the `init`s exist soley to be able to set the transitionStyle.
    required init?(coder aDecoder: NSCoder) {
        self.init()
    }

    /// init KeySyncWizardViewController, to guide the user with the KeySync proccess.
    ///
    /// - Parameters:
    ///   - me: my trust words
    ///   - partner: my partner trust words
    ///   - isNewGroup: is it a new group creation or i am joining an existing group
    ///   - completion: handle the possible results of type PEPSyncHandshakeResult
    static func fromStoryboard(meFPR: String,
                               partnerFPR: String,
                               isNewGroup: Bool,
                               completion: @escaping (Action) -> Void) -> KeySyncWizardViewController? {
        guard let createe = fromStoryboard() else {
            Log.shared.errorAndCrash("Missing wizzard")
            return nil
        }
        createe.setup(pageCompletion: completion,
                      meFPR: meFPR,
                      partnerFPR: partnerFPR,
                      isNewGroup: isNewGroup)
        createe.modalTransitionStyle = .crossDissolve
        createe.modalPresentationStyle = .overFullScreen

        return createe
    }
}

// MARK: - Private

extension KeySyncWizardViewController {

    static private func fromStoryboard() -> KeySyncWizardViewController? {
        let storyboard = UIStoryboard(name: Constants.keySyncWizardStoryboard, bundle: .main)
        guard
            let wizzardVC = storyboard.instantiateViewController(
                withIdentifier: storyboardId) as? KeySyncWizardViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController PEPAlertViewController")
                    return nil
        }
        wizzardVC.isScrollEnable = false
        wizzardVC.pageControlTint = nil
        wizzardVC.pageControlPageIndicatorColor = nil
        wizzardVC.showDots = false
        wizzardVC.pageControlBackgroundColor = nil

        return wizzardVC
    }

    private func setup(pageCompletion: @escaping (Action) -> Void,
                       meFPR: String,
                       partnerFPR: String,
                       isNewGroup: Bool) {
        self.views = wizardViews(pageCompletion: pageCompletion,
                                 meFPR: meFPR,
                                 partnerFPR: partnerFPR,
                                 isNewGroup: isNewGroup)
    }

    private func wizardViews(pageCompletion: @escaping (Action) -> Void,
                             meFPR: String,
                             partnerFPR: String,
                             isNewGroup: Bool) -> [UIViewController] {

            guard let introView = introView(isNewGroup: isNewGroup,
                                            pageCompletion: pageCompletion),
                let trustWordsView = trustWordsView(meFPR: meFPR,
                                                    partnerFPR: partnerFPR,
                                                    pageCompletion: pageCompletion),
                let animationView = animationView(pageCompletion: pageCompletion),
                let completionView = completionView(isNewGroup: isNewGroup,
                                                    pageCompletion: pageCompletion) else {
                                                        return []
            }

            return [introView, trustWordsView, animationView, completionView]
    }

    private func introView(isNewGroup: Bool,
                           pageCompletion: @escaping (Action) -> Void)
        -> PEPAlertViewController? {

            let keySyncIntroTitle = alertTitle()
            let keySyncIntroMessage = introMessage(isNewGroup: isNewGroup)

            guard let introView = PEPAlertViewController.fromStoryboard(title: keySyncIntroTitle,
                                                                        message: keySyncIntroMessage,
                                                                        paintPEPInTitle: true,
                                                                        image: [#imageLiteral(resourceName: "pEpForiOS-icon-device-detected")]) else {
                                                                            return nil
            }

            let notNowButtonTitle = NSLocalizedString("Not Now",
                                                      comment: "keySyncWizard intro view Not Now button title")
            let introNotNowAction = PEPUIAlertAction(title: notNowButtonTitle,
                                                     style: .pEpGray,
                                                     handler: { [weak self] alert in
                                                        pageCompletion(.cancel)
                                                        self?.dismiss()
            })

            let nextButtonTitle = NSLocalizedString("Next",
                                                    comment: "keySyncWizard intro view Next button title")
            let introNextAction = PEPUIAlertAction(title: nextButtonTitle,
                                                   style: .pEpBlue,
                                                   handler: { [weak self] alert in
                                                    self?.goToNextView()
            })

            introView.add(action: introNotNowAction)
            introView.add(action: introNextAction)

            return introView
    }

    private func trustWordsView(meFPR: String,
                                partnerFPR: String,
                                pageCompletion: @escaping (Action) -> Void) -> KeySyncHandshakeViewController? {
        let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
        guard let handShakeViewController = storyboard.instantiateViewController(
            withIdentifier: KeySyncHandshakeViewController.storyboardId) as? KeySyncHandshakeViewController else {
                Log.shared.errorAndCrash("Fail to instantiateViewController KeySyncHandshakeViewController")
                return nil
        }
        handShakeViewController.completionHandler { [weak self] action in
            switch action {
            case .accept:
                pageCompletion(.accept)
                self?.goToNextView()
            case .cancel:
                pageCompletion(.cancel)
                self?.dismiss()
            case .decline:
                pageCompletion(.decline)
                self?.dismiss()
            }
        }

        handShakeViewController.finderPrints(meFPR: meFPR, partnerFPR: partnerFPR)

        return handShakeViewController
    }

    private func animationView(pageCompletion: @escaping (Action) -> Void)
        -> PEPAlertViewController? {
            let animatioTitle = alertTitle()
            let animatioMessage = NSLocalizedString("Please give us a moment while we sync your devices. This can take up to a minute.",
                                                    comment: "keySyncWizard animation view message")

            let pepAlertViewController =
                PEPAlertViewController.fromStoryboard(title: animatioTitle,
                                                      message: animatioMessage,
                                                      paintPEPInTitle: true,
                                                      image: [#imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-1"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2"), #imageLiteral(resourceName: "pEpForiOS-icon-device-group"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-animation-2")])

            let animatioCanceButtonlTitle = NSLocalizedString("Cancel",
                                                              comment: "keySyncWizard animation view cancel button title")
            let animatioCancelAction = PEPUIAlertAction(title: animatioCanceButtonlTitle,
                                                        style: .pEpBlue,
                                                        handler: { [weak self] alert in
                                                            pageCompletion(.cancel)
                                                            self?.dismiss()
            })
            pepAlertViewController?.add(action: animatioCancelAction)
            return pepAlertViewController
    }

    private func completionView(isNewGroup: Bool,
                                pageCompletion: @escaping (Action) -> Void) -> PEPAlertViewController? {
        let completionTitle = alertTitle()
        let completionMessage = completeMessage(isNewGroup: isNewGroup)

        let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: completionTitle,
                                                  message: completionMessage,
                                                  paintPEPInTitle: true,
                                                  image: [#imageLiteral(resourceName: "pEpForiOS-icon-device-group")])

        let completionLeavelTitle = NSLocalizedString("Leave",
                                                      comment: "keySyncWizard completion view leave button title")
        let completionLeavelAction = PEPUIAlertAction(title: completionLeavelTitle,
                                                      style: .pEpRed,
                                                      handler: { [weak self] alert in
                                                        self?.leaveDeviceGroup()
                                                        self?.dismiss()
        })

        let completionOKlTitle = NSLocalizedString("OK",
                                                   comment: "keySyncWizard completion view OK button title")
        let completionOKlAction = PEPUIAlertAction(title: completionOKlTitle,
                                                   style: .pEpBlue,
                                                   handler: { [weak self] alert in
                                                    self?.dismiss()
        })
        pepAlertViewController?.add(action: completionLeavelAction)
        pepAlertViewController?.add(action: completionOKlAction)
        return pepAlertViewController
    }

    private func leaveDeviceGroup() {
        do {
            try KeySyncDeviceGroupUtil.leaveDeviceGroup()
        } catch {
            Log.shared.errorAndCrash("%@", error.localizedDescription)
        }
    }

    private func introMessage(isNewGroup: Bool) -> String {
        if isNewGroup {
            return NSLocalizedString("A second device is detected. We can form a device group to sync all your privacy on both devices. Shall we start synchronizing?",
                                     comment: "KeySyncWizard introduction message")
        } else {
            return NSLocalizedString("Another device is detected. We can add it to your device group to sync all your privacy on all devices. Shall we start synchronizing?",
                                     comment: "KeySyncWizard introduction message")
        }
    }

    private func completeMessage(isNewGroup: Bool) -> String {
        if isNewGroup {
            return "We successfully created a device group. All your privacy is now synchronized."
        } else {
            return "The device is now member of your device group. All your privacy is now synchronized."
        }
    }

    private func alertTitle() -> String {
        return NSLocalizedString("p≡p Sync", comment: "keySyncWizard animation view title")
    }
}
