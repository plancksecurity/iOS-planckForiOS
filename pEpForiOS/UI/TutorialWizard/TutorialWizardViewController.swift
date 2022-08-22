//
//  TutorialWizardViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 02/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

/// View Controller that handles the tutorial
final class TutorialWizardViewController: PEPPageViewControllerBase {
    private static let storyboardId = "TutorialWizardViewController"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                view.backgroundColor = .secondarySystemBackground
            } else {
                view.backgroundColor = .white
            }
            Appearance.customiseForTutorial(viewController: self)
        } else {
            view.backgroundColor = .white
        }
    }

    /// Presents the tutorial wizard
    ///
    /// - Parameter viewController: The base view controller to present the tutorial.
    /// This allows to present the tutorial from several places.
    public static func presentTutorialWizard(viewController: UIViewController) {
        let storyboardName = UIDevice.isIpad ? Constants.tutorialiPadStoryboard : Constants.tutorialiPhoneStoryboard
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)
        guard let tutorialWizard = storyboard.instantiateViewController(withIdentifier: storyboardId) as? TutorialWizardViewController else {
            Log.shared.errorAndCrash("Fail to instantiateViewController TutorialWizardViewController")
            return
        }
        tutorialWizard.modalPresentationStyle = .overFullScreen
        tutorialWizard.isScrollEnable = true
        tutorialWizard.showDots = true
        tutorialWizard.pageControlTint = .pEpGray

        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                tutorialWizard.pageControlTint = .lightGray
                tutorialWizard.pageControlPageIndicatorColor = .white
                tutorialWizard.pageControlBackgroundColor = .secondarySystemBackground
            } else {
                tutorialWizard.pageControlPageIndicatorColor = .black
                tutorialWizard.pageControlBackgroundColor = .white
            }
        } else {
            tutorialWizard.pageControlPageIndicatorColor = .black
            tutorialWizard.pageControlBackgroundColor = .white
        }
        let navigationController = UINavigationController(rootViewController: tutorialWizard)
        DispatchQueue.main.async { [weak viewController] in
            navigationController.modalPresentationStyle = .fullScreen
            viewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    override func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        super.pageViewController(pageViewController, didFinishAnimating: finished, previousViewControllers: previousViewControllers, transitionCompleted: completed)
        updateNavButton(lastScreen: isLast())
    }
}

// MARK: - Private

extension TutorialWizardViewController {
    
    private func setupView() {
        views = tutorialViewControllers()
        view.backgroundColor = .white
        navigationController?.navigationBar.barTintColor = .pEpGreen
        navigationController?.navigationBar.tintColor = .white
        updateNavButton(lastScreen: false)
    }
    
    //Staring point
    private func tutorialViewControllers() -> [UIViewController] {
        var result = [UIViewController]()

        let storyboardName = UIDevice.isIpad ? Constants.tutorialiPadStoryboard : Constants.tutorialiPhoneStoryboard
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)

        //We have 4 steps in the tutorial.
        for step in 0...3 {
            let stepViewController = storyboard.instantiateViewController(withIdentifier: "TutorialStep\(step)ViewController")
            result.append(stepViewController)
        }
        return result
    }

    /// Close the tutorial.
    @objc private func closeScreen() {
        dismiss(animated: true)
    }

    /// Updates the right bar button, regarding if it's the last element or not.
    /// - Parameter lastScreen: Indicates if it's the last screen.
    private func updateNavButton(lastScreen: Bool) {
        var navBarButtonTitle: String? = nil
        var accessibilityIdentifier: String? = nil

        if lastScreen {
            navBarButtonTitle = NSLocalizedString("Finish", comment: "Start up tutorial finish button")
            accessibilityIdentifier = AccessibilityIdentifier.tutorialfinishButton
        } else {
            navBarButtonTitle = NSLocalizedString("Skip", comment: "Start up tutorial skip button")
            accessibilityIdentifier = AccessibilityIdentifier.tutorialSkipButton
        }

        let endButton = UIBarButtonItem(title: navBarButtonTitle, style: .done, target: self, action: #selector(closeScreen))

        endButton.accessibilityIdentifier = accessibilityIdentifier

        navigationItem.rightBarButtonItem = endButton
    }
}

// MARK: - Trait Collection

extension TutorialWizardViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    pageControlTint = .lightGray
                    pageControlPageIndicatorColor = .white
                    pageControlBackgroundColor = .secondarySystemBackground
                    view.backgroundColor = .secondarySystemBackground
                } else {
                    pageControlPageIndicatorColor = .black
                    pageControlBackgroundColor = .white
                    view.backgroundColor = .white
                }

                view.layoutIfNeeded()
            }
        }
    }
}
