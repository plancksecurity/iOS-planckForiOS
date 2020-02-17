//
//  Appearance.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 1/19/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class Appearance {
    public static func pEp(_ color: UIColor = .pEpGreen) {
        // Still needed for iOS 13 for button bar items.
        UINavigationBar.appearance().tintColor = color

        if #available(iOS 13, *) {
            // iOS 13 ignores the navigation bar tint color in some cases,
            // therefore we use the new appearance API to customise explicitly.
            let normalNavigationBar = UINavigationBar.appearance()
            normalNavigationBar.standardAppearance = navigationBarAppearanceDefault(color: color)
        } else {
            UINavigationBar.appearance().backgroundColor = .white
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: color]
        }

        UIToolbar.appearance().backgroundColor = color
        UIToolbar.appearance().barTintColor = color
        UIToolbar.appearance().tintColor = .white

        UITextView.appearance().tintColor = color
        UITextField.appearance().tintColor = color

        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().tintColor = color
        if #available(iOS 13, *) {
            // The navigation bar doesn't react to setting the tint color,
            // so better do nothing there at all.
        } else {
            UINavigationBar.appearance().barTintColor = .pEpNavigation
            UISearchBar.appearance().backgroundColor = .pEpNavigation
        }

        setAlertControllerTintColor(color)

        Appearance.configureSelectedBackgroundViewForPep(
            tableViewCell: UITableViewCell.appearance())
    }

    public static func configureSelectedBackgroundViewForPep(tableViewCell: UITableViewCell) {
        let tableViewCellSelectedbackgroundView = UIView()
        tableViewCellSelectedbackgroundView.backgroundColor =
            UIColor.pEpGreen.withAlphaComponent(0.2)
        tableViewCell.selectedBackgroundView = tableViewCellSelectedbackgroundView
    }

    private static func setAlertControllerTintColor(_ color: UIColor = .pEpGreen) {
        let view = UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self])
        view.tintColor = color
    }

    // MARK: - iOS 13

    /// Default appearance for navigation bars (iOS 13 and upwards).
    @available(iOS 13, *)
    static private func navigationBarAppearanceDefault(color: UIColor) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()

        appearance.configureWithOpaqueBackground()
        let defaultpEpTextAttributes: [NSAttributedString.Key : Any] =
            [.foregroundColor: color]
        let titlepEpTextAttributes: [NSAttributedString.Key : Any] =
            [.foregroundColor: UIColor.black,
             .font: UIFont.pepFont(style: .body, weight: .semibold)]
        appearance.buttonAppearance.normal.titleTextAttributes = defaultpEpTextAttributes
        appearance.backButtonAppearance.normal.titleTextAttributes = defaultpEpTextAttributes
        appearance.titleTextAttributes = titlepEpTextAttributes
        appearance.largeTitleTextAttributes = defaultpEpTextAttributes
        appearance.doneButtonAppearance.normal.titleTextAttributes = defaultpEpTextAttributes

        let chevronLeftImg = UIImage(named: "chevron-left-original")
        appearance.setBackIndicatorImage(chevronLeftImg, transitionMaskImage: chevronLeftImg)

        return appearance
    }

    /// Customises the buttons of a navigation bar appearance, for the tutorial and login view.
    /// - Parameter navigationBarAppearance: The appearance to customize.
    @available(iOS 13, *)
    static private func customiseButtons(navigationBarAppearance: UINavigationBarAppearance) {
        let titleTextAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.white]
        navigationBarAppearance.buttonAppearance.normal.titleTextAttributes = titleTextAttributes
        navigationBarAppearance.backButtonAppearance.normal.titleTextAttributes = titleTextAttributes
        navigationBarAppearance.titleTextAttributes = titleTextAttributes
        navigationBarAppearance.largeTitleTextAttributes = titleTextAttributes
        navigationBarAppearance.doneButtonAppearance.normal.titleTextAttributes = titleTextAttributes
    }

    /// Customises a navigation bar appearance for the login view.
    /// - Parameter navigationBarAppearance: The appearance to customize.
    @available(iOS 13, *)
    static private func customiseForLogin(navigationBarAppearance: UINavigationBarAppearance) {
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = UIColor.clear
        customiseButtons(navigationBarAppearance: navigationBarAppearance)
    }

    /// Customises a navigation bar appearance for the tutorial view.
    /// - Parameter navigationBarAppearance: The appearance to customize.
    @available(iOS 13, *)
    static private func customiseForTutorial(navigationBarAppearance: UINavigationBarAppearance) {
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor.pEpGreen
        customiseButtons(navigationBarAppearance: navigationBarAppearance)
    }

    /// Helper for changing the appearance of a navigation bar containing a view controller.
    /// - Parameter viewController: The view controller that is embedded in a navigation controller.
    /// - Parameter appearanceModifier: A block that will modify the navigation bar appearance.
    @available(iOS 13, *)
    static private func customiseNavigationBar(viewController: UIViewController,
                                               appearanceModifier: (UINavigationBarAppearance) -> Void) {
        if let navigationController = viewController.navigationController {
            let appearance = navigationController.navigationBar.standardAppearance.copy()
            appearanceModifier(appearance)
            viewController.navigationItem.standardAppearance = appearance
        }
    }

    /// Customises a tutorial view controller's navigation bar appearance.
    /// - Parameter viewController: UIViewController: The view controller to customize.
    @available(iOS 13, *)
    static func customiseForTutorial(viewController: UIViewController) {
        customiseNavigationBar(viewController: viewController) { appearance in
            customiseForTutorial(navigationBarAppearance: appearance)
        }
    }

    /// Customises a login view controller's navigation bar appearance.
    /// - Parameter viewController: UIViewController: The view controller to customize.
    @available(iOS 13, *)
    static func customiseForLogin(viewController: UIViewController) {
        customiseNavigationBar(viewController: viewController) { appearance in
            customiseForLogin(navigationBarAppearance: appearance)
        }
    }
}
