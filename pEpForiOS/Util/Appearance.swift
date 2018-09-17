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
    static func pEp(_ color: UIColor = .pEpGreen) {
        UINavigationBar.appearance().backgroundColor = .white
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().tintColor = color
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().titleTextAttributes =
            [NSAttributedStringKey.foregroundColor: color]

        UIToolbar.appearance().backgroundColor = color
        UIToolbar.appearance().barTintColor = color
        UIToolbar.appearance().tintColor = .white

        UITextView.appearance().tintColor = color
        UITextField.appearance().tintColor = color

        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().backgroundColor = .white
        UISearchBar.appearance().tintColor = color

        setAlertControllerTintColor(color)

        let tableViewCellSelectedbackgroundView = UIView()
        tableViewCellSelectedbackgroundView.backgroundColor = UIColor.pEpGreen.rgbWith(alpha: 0.2)
        UITableViewCell.appearance().selectedBackgroundView = tableViewCellSelectedbackgroundView
    }

    private static func setAlertControllerTintColor(_ color: UIColor = .pEpGreen) {
        let view = UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self])
        view.tintColor = color
    }
}
