//
//  KeySyncWizardViewController.swift
//  pEp
//
//  Created by Andreas Buff on 15.11.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

extension KeySyncWizardViewController {

    enum Action {
        case cancel
        case decline
        case accept
    }
}

final class KeySyncWizardViewController: PEPPageViewControllerBase {
    static let storyboardId = "KeySyncWizardViewController"
    private(set) var isNewGroup = true

    // MARK: - Life Cycle

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

    // MARK: -

    var isCurrentlyShowingSuccessfullyGroupedView: Bool {
        return isLast()
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
            Log.shared.errorAndCrash("Missing wizard")
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
            let wizardVC = storyboard.instantiateViewController(
                withIdentifier: storyboardId) as? KeySyncWizardViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController PEPAlertViewController")
                    return nil
        }
        wizardVC.isScrollEnable = false
        wizardVC.pageControlTint = nil
        wizardVC.pageControlPageIndicatorColor = nil
        wizardVC.showDots = false
        wizardVC.pageControlBackgroundColor = nil
        return wizardVC
    }

    private func setup(pageCompletion: @escaping (Action) -> Void,
                       meFPR: String,
                       partnerFPR: String,
                       isNewGroup: Bool) {
        self.isNewGroup = isNewGroup
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
                                                    isNewGroup: isNewGroup,
                                                    pageCompletion: pageCompletion),
                let animationView = animationView(isNewGroup: isNewGroup,
                                                  pageCompletion: pageCompletion),
                let completionView = completionView(isNewGroup: isNewGroup,
                                                    pageCompletion: pageCompletion) else {
                                                        return []
            }


            return [introView, trustWordsView, animationView, completionView]
    }

    private func introView(isNewGroup: Bool,
                           pageCompletion: @escaping (Action) -> Void)
        -> PEPAlertViewController? {

            let keySyncIntroTitle = completeTitle()
            let keySyncIntroMessage = introMessage(isNewGroup: isNewGroup)
            let keySyncIntroImage = isNewGroup ? #imageLiteral(resourceName: "pEpForiOS-icon-sync-2nd-device") : #imageLiteral(resourceName: "pEpForiOS-icon-sync-3rd-device")

            guard let introView =
                PEPAlertViewController.fromStoryboard(title: keySyncIntroTitle,
                                                      message: keySyncIntroMessage,
                                                      paintPEPInTitle: true,
                                                      image: [keySyncIntroImage],
                                                      viewModel: PEPAlertViewModel(alertType: .pEpSyncWizard)) else {
                                                        return nil
            }

            let notNowButtonTitle = NSLocalizedString("Not Now",
                                                      comment: "keySyncWizard intro view Not Now button title")
            let introNotNowAction = PEPUIAlertAction(title: notNowButtonTitle,
                                                     style: .pEpGreyText,
                                                     handler: { [weak self] alert in
                                                        pageCompletion(.cancel)
                                                        self?.dismiss()
            })

            let nextButtonTitle = NSLocalizedString("Next",
                                                    comment: "keySyncWizard intro view Next button title")
            let introNextAction = PEPUIAlertAction(title: nextButtonTitle,
                                                   style: .pEpTextDark,
                                                   handler: { [weak self] alert in
                                                    self?.goToNextView()
            })


            introView.add(action: introNotNowAction)
            introView.add(action: introNextAction)

            return introView
    }

    private func trustWordsView(meFPR: String,
                                partnerFPR: String,
                                isNewGroup: Bool,
                                pageCompletion: @escaping (Action) -> Void) -> KeySyncHandshakeViewController? {
        let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
        guard let handShakeViewController = storyboard.instantiateViewController(
            withIdentifier: KeySyncHandshakeViewController.storyboardId) as? KeySyncHandshakeViewController else {
                Log.shared.errorAndCrash("Fail to instantiateViewController KeySyncHandshakeViewController")
                return nil
        }
        handShakeViewController.completionHandler { [weak self] action in

            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            switch action {
            case .accept:
                pageCompletion(.accept)
                me.goToNextView()
            case .cancel:
                pageCompletion(.cancel)
                me.dismiss()
            case .decline:
                pageCompletion(.decline)
                me.dismiss()
            }
        }

        handShakeViewController.setFingerPrints(meFPR: meFPR,
                                                partnerFPR: partnerFPR,
                                                isNewGroup: isNewGroup)

        return handShakeViewController
    }

    private func animationView(isNewGroup: Bool, pageCompletion: @escaping (Action) -> Void)
        -> PEPAlertViewController? {

            let message = NSLocalizedString("Please give us a moment while we sync your devices. This can take a minute or more.",
                                            comment: "keySyncWizard animation view message while we sync your devices")

            let animationTitle = completeTitle()
            let animationMessage = message
            let animationImages = isNewGroup
                ? [#imageLiteral(resourceName: "pEpForiOS-icon-sync-2nd-device-syncing"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-2nd-device-synced")]
                : [#imageLiteral(resourceName: "pEpForiOS-icon-sync-3rd-device-syncing"), #imageLiteral(resourceName: "pEpForiOS-icon-sync-3rd-device-synced")]

            let pepAlertViewController =
                PEPAlertViewController.fromStoryboard(title: animationTitle,
                                                      message: animationMessage,
                                                      paintPEPInTitle: true,
                                                      image: animationImages,
                                                      viewModel: PEPAlertViewModel(alertType: .pEpSyncWizard))

            let animationCanceButtonlTitle = NSLocalizedString("Cancel",
                                                              comment: "keySyncWizard animation view cancel button title")
            let animationCancelAction = PEPUIAlertAction(title: animationCanceButtonlTitle,
                                                        style: .pEpTextDark,
                                                        handler: { [weak self] alert in
                                                            pageCompletion(.cancel)
                                                            self?.dismiss()
            })
            pepAlertViewController?.add(action: animationCancelAction)
            return pepAlertViewController
    }

    private func completionView(isNewGroup: Bool,
                                pageCompletion: @escaping (Action) -> Void) -> PEPAlertViewController? {

        let completionTitle = completeTitle()
        let completionMessage = completeMessage(isNewGroup: isNewGroup)
        let completionImage = completeImage(isNewGroup: isNewGroup)

        let pepAlertViewController =
            PEPAlertViewController.fromStoryboard(title: completionTitle,
                                                  message: completionMessage,
                                                  paintPEPInTitle: true,
                                                  image: [completionImage],
                                                  viewModel: PEPAlertViewModel(alertType: .pEpSyncWizard))

        let completionLeaveTitle = NSLocalizedString("Leave",
                                                      comment: "keySyncWizard completion view leave button title")
        let completionLeaveAction = PEPUIAlertAction(title: completionLeaveTitle,
                                                      style: .pEpGreyText,
                                                      handler: { [weak self] alert in
                                                        self?.leaveDeviceGroup()
                                                        self?.dismiss()
        })

        let completionOKTitle = NSLocalizedString("OK",
                                                   comment: "keySyncWizard completion view OK button title")
        let completionOKlAction = PEPUIAlertAction(title: completionOKTitle,
                                                   style: .pEpTextDark,
                                                   handler: { [weak self] alert in
                                                    self?.dismiss()
        })
        pepAlertViewController?.add(action: completionLeaveAction)
        pepAlertViewController?.add(action: completionOKlAction)
        return pepAlertViewController
    }

    private func leaveDeviceGroup() {
        KeySyncUtil.leaveDeviceGroup() {
            // Nothing to do.
        }
    }

    private func introMessage(isNewGroup: Bool) -> String {
        if isNewGroup {
            return NSLocalizedString("A second device was detected. We can form a device group to sync all your privacy on both devices. Shall we start synchronizing?",
                                     comment: "KeySyncWizard introduction message ")
        } else {
            return NSLocalizedString("Another device was detected. We can add it to your device group to sync all your privacy on all devices. Shall we start synchronizing?",
                                     comment: "KeySyncWizard introduction message")
        }
    }

    private func completeTitle() -> String {
        return NSLocalizedString("p≡p Sync",
                                 comment: "keySyncWizard animation view title")
    }

    private func completeMessage(isNewGroup: Bool) -> String {
        if isNewGroup {
            return NSLocalizedString("We successfully created a device group. All your privacy is now synchronized.", comment: "KeySyncWizard complete message - two devices")
        } else {
            return NSLocalizedString("The device is now member of your device group. All your privacy is now synchronized.", comment: "KeySyncWizard complete message - more than two devices")
        }
    }

    private func completeImage(isNewGroup: Bool) -> UIImage {
        return isNewGroup ? #imageLiteral(resourceName: "pEpForiOS-icon-sync-2nd-device-synced") : #imageLiteral(resourceName:   "pEpForiOS-icon-sync-3rd-device-synced")
    }
}
