//
//  KeySyncWizardViewController.swift
//  pEp
//
//  Created by Andreas Buff on 15.11.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel // for KeySyncHandshakeData
import PlanckToolbox

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

    private var style: UIColor = {
        return .label
    }()

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
        UIApplication.shared.disableAutoLockingDevice()
    }

    deinit {
        UIApplication.shared.enableAutoLockingDevice()
    }

    // MARK: -

    var isCurrentlyShowingSuccessfullyGroupedView: Bool {
        return isLast()
    }

    /// init KeySyncWizardViewController, to guide the user with the KeySync proccess.
    ///
    /// - Parameters:
    ///   - keySyncHandshakeData: All data needod for a key sync handshake
    ///   - completion: handle the possible results of type PEPSyncHandshakeResult
    static func fromStoryboard(keySyncHandshakeData: KeySyncHandshakeData,
                               completion: @escaping (Action) -> Void) -> KeySyncWizardViewController? {
        guard let createe = fromStoryboard() else {
            Log.shared.errorAndCrash("Missing wizard")
            return nil
        }
        createe.setup(keySyncHandshakeData: keySyncHandshakeData,
                      pageCompletion: completion)
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

    private func setup(keySyncHandshakeData: KeySyncHandshakeData,
                       pageCompletion: @escaping (Action) -> Void) {
        self.isNewGroup = keySyncHandshakeData.isNewGroup
        self.views = wizardViews(keySyncHandshakeData: keySyncHandshakeData,
                                 pageCompletion: pageCompletion)
    }

    private func wizardViews(keySyncHandshakeData: KeySyncHandshakeData,
                             pageCompletion: @escaping (Action) -> Void) -> [UIViewController] {

        guard let introView = introView(isNewGroup: isNewGroup,
                                        pageCompletion: pageCompletion),
              let trustWordsView = trustWordsView(keySyncHandshakeData: keySyncHandshakeData,
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
                                               style: style,
                                               handler: { [weak self] alert in
                                                self?.goToNextView()
                                               })


        introView.add(action: introNotNowAction)
        introView.add(action: introNextAction)

        return introView
    }

    private func trustWordsView(keySyncHandshakeData: KeySyncHandshakeData,
                                pageCompletion: @escaping (Action) -> Void) -> KeySyncHandshakeViewController? {
        let storyboard = UIStoryboard(name: Constants.reusableStoryboard, bundle: .main)
        guard let handShakeViewController = storyboard.instantiateViewController(
            withIdentifier: KeySyncHandshakeViewController.storyboardId) as? KeySyncHandshakeViewController else {
                Log.shared.errorAndCrash("Fail to instantiateViewController KeySyncHandshakeViewController")
                return nil
        }
        handShakeViewController.completionHandler { [weak self] action in

            guard let me = self else {
                Log.shared.lostMySelf()
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

        handShakeViewController.setKeySyncHandshakeData(keySyncHandshakeData: keySyncHandshakeData)

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
                                                        style: style,
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
                                                   style: style,
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
        return NSLocalizedString("planck Sync",
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

// MARK: - Trait Collection

extension KeySyncWizardViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            view.layoutIfNeeded()
        }
    }
}
