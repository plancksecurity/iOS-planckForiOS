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
        UINavigationBar.appearance().backgroundColor = .white
        UINavigationBar.appearance().barTintColor = .pEpNavigation
        UINavigationBar.appearance().tintColor = color
        UINavigationBar.appearance().titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: color]

        UIToolbar.appearance().backgroundColor = color
        UIToolbar.appearance().barTintColor = color
        UIToolbar.appearance().tintColor = .white

        UITextView.appearance().tintColor = color
        UITextField.appearance().tintColor = color

        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().backgroundColor = .pEpNavigation
        UISearchBar.appearance().tintColor = color

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
}
