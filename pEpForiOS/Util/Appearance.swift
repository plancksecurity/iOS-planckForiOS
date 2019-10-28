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
        if #available(iOS 13, *) {
            // iOS 13 introduced a new appearance API, keeping compatibility with the old way.
            // Unfortunately, the pre-iOS-13 UINavigationBar.appearance().tintColor
            // is not respected anymore in all cases.
            let normalNavigationBar = UINavigationBar.appearance()
            normalNavigationBar.standardAppearance = navigationBarAppearanceDefault(color: color)
        } else {
            UINavigationBar.appearance().backgroundColor = .white
            UINavigationBar.appearance().tintColor = color
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

    /// Default appearance for navigation bars (iOS 13 and upwards).
    @available(iOS 13, *)
    static func navigationBarAppearanceDefault(color: UIColor) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()

        appearance.configureWithOpaqueBackground()
        let titleTextAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: color]
        appearance.buttonAppearance.normal.titleTextAttributes = titleTextAttributes
        appearance.backButtonAppearance.normal.titleTextAttributes = titleTextAttributes
        appearance.titleTextAttributes = titleTextAttributes
        appearance.largeTitleTextAttributes = titleTextAttributes
        appearance.doneButtonAppearance.normal.titleTextAttributes = titleTextAttributes

        let chevronLeftImg = UIImage(named: "chevron-left-original")
        appearance.setBackIndicatorImage(chevronLeftImg, transitionMaskImage: chevronLeftImg)

        return appearance
    }

    /// Appearance for tutorial and login view navigation bars (iOS 13 and upwards).
    @available(iOS 13, *)
    static func navigationBarAppearanceTutorial(color: UIColor) -> UINavigationBarAppearance {
        let appearance = navigationBarAppearanceDefault(color: color)

        let titleTextAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance.normal.titleTextAttributes = titleTextAttributes
        appearance.backButtonAppearance.normal.titleTextAttributes = titleTextAttributes
        appearance.titleTextAttributes = titleTextAttributes
        appearance.largeTitleTextAttributes = titleTextAttributes
        appearance.doneButtonAppearance.normal.titleTextAttributes = titleTextAttributes

        appearance.backgroundColor = color

        return appearance
    }
}
