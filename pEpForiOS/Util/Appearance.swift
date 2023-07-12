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

    /// Sets up the default appeareance configuration
    /// This method defines tint color and backgrounds for navigation bars, toolbars,
    /// textviews, textfields and searchbars.
    public static func setup() {
        // Still needed for iOS 13 for button bar items.
        UINavigationBar.appearance().tintColor = .primary

        // iOS 13 ignores the navigation bar tint color in some cases,
        // therefore we use the new appearance API to customise explicitly.
        let normalNavigationBar = UINavigationBar.appearance()
        normalNavigationBar.standardAppearance = navigationBarAppearanceDefault(color: UIColor.label)
        normalNavigationBar.scrollEdgeAppearance = normalNavigationBar.standardAppearance

        UIToolbar.appearance().backgroundColor = .primary
        UIToolbar.appearance().barTintColor = .primary
        UIToolbar.appearance().tintColor = .white
        if #available(iOS 15.0, *) {
            let appearance = UIToolbarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .primary
            UIToolbar.appearance().standardAppearance = appearance
            UIToolbar.appearance().scrollEdgeAppearance = UIToolbar.appearance().standardAppearance
        }

        UITextView.appearance().tintColor = .primary
        UITextField.appearance().tintColor = .primary

        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().tintColor = .primary

        setAlertControllerTintColor(.primary)

        Appearance.configureSelectedBackgroundViewForPep(tableViewCell: UITableViewCell.appearance())

        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.systemBackground
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.primary
        UISearchBar.appearance().backgroundColor = UIColor.systemBackground
    }

    /// Configure the background view of the table view cells.
    /// - Parameter tableViewCell: The cell to set the background view.
    public static func configureSelectedBackgroundViewForPep(tableViewCell: UITableViewCell) {
        let backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor.systemGray5 : UIColor.primary.withAlphaComponent(0.2)
        let tableViewCellSelectedbackgroundView = UIView()
        tableViewCellSelectedbackgroundView.backgroundColor = backgroundColor
        tableViewCell.selectedBackgroundView = tableViewCellSelectedbackgroundView
    }

    /// Customises a login view controller's navigation bar appearance.
    /// - Parameter viewController: UIViewController: The view controller to customize.
    public static func customiseForLogin(viewController: UIViewController) {
        customiseNavigationBar(viewController: viewController) { appearance in
            customiseForLogin(navigationBarAppearance: appearance)
        }
    }
}

//MARK: - Private

extension Appearance {

    private static func setAlertControllerTintColor(_ color: UIColor = .primary) {
        let view = UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self])
        view.tintColor = color
    }

    /// Return custom pEp titleTextAttributes
    static private func titleTextAttributes() -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: UIColor.black]
    }

    /// Default appearance for navigation bars (iOS 13 and upwards).
    static private func navigationBarAppearanceDefault(color: UIColor) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        let font = UIFont.pepFont(style: .headline, weight: .medium)
        let titleTextAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: color,
                                                                   .font: font]
        let buttonsAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.primary]
        appearance.buttonAppearance.normal.titleTextAttributes = buttonsAttributes
        appearance.titleTextAttributes = titleTextAttributes
        appearance.largeTitleTextAttributes = titleTextAttributes
        appearance.doneButtonAppearance.normal.titleTextAttributes = buttonsAttributes
        let chevronLeftImg = UIImage(named: "chevron-icon-left")?
            .resizeImage(targetSize: CGSize(width: 15, height: 25))

        appearance.setBackIndicatorImage(chevronLeftImg, transitionMaskImage: chevronLeftImg)
        return appearance
    }

    /// Customises the buttons of a navigation bar appearance, for the login view.
    /// - Parameter navigationBarAppearance: The appearance to customize.
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
    static private func customiseForLogin(navigationBarAppearance: UINavigationBarAppearance) {
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = UIColor.clear
        let newTintImage = UIImage(named: "white-chevron-icon-left")!.withRenderingMode(.alwaysOriginal)
        navigationBarAppearance.setBackIndicatorImage(newTintImage, transitionMaskImage: newTintImage)
        customiseButtons(navigationBarAppearance: navigationBarAppearance)
    }

    /// Helper for changing the appearance of a navigation bar containing a view controller.
    /// - Parameter viewController: The view controller that is embedded in a navigation controller.
    /// - Parameter appearanceModifier: A block that will modify the navigation bar appearance.
    static private func customiseNavigationBar(viewController: UIViewController,
                                               appearanceModifier: (UINavigationBarAppearance) -> Void) {
        if let navigationController = viewController.navigationController {
            let appearance = navigationController.navigationBar.standardAppearance.copy()
            appearanceModifier(appearance)
            viewController.navigationItem.standardAppearance = appearance
            viewController.navigationItem.scrollEdgeAppearance = appearance
        }
    }
}
