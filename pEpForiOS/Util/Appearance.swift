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
        UINavigationBar.appearance().tintColor = .pEpGreen

        if #available(iOS 13, *) {
            // iOS 13 ignores the navigation bar tint color in some cases,
            // therefore we use the new appearance API to customise explicitly.
            let normalNavigationBar = UINavigationBar.appearance()
            normalNavigationBar.standardAppearance = navigationBarAppearanceDefault(color: .black)
        } else {
            UINavigationBar.appearance().backgroundColor = .white
            UINavigationBar.appearance().titleTextAttributes = titleTextAttributes()
        }

        UIToolbar.appearance().backgroundColor = .pEpGreen
        UIToolbar.appearance().barTintColor = .pEpGreen
        UIToolbar.appearance().tintColor = .white

        UITextView.appearance().tintColor = .pEpGreen
        UITextField.appearance().tintColor = .pEpGreen

        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().tintColor = .pEpGreen
        if #available(iOS 13, *) {
            // The navigation bar doesn't react to setting the tint color,
            // so better do nothing there at all.
        } else {
            UINavigationBar.appearance().barTintColor = .pEpNavigation
            UISearchBar.appearance().backgroundColor = .pEpNavigation
        }

        setAlertControllerTintColor(.pEpGreen)

        Appearance.configureSelectedBackgroundViewForPep(tableViewCell: UITableViewCell.appearance())
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

    /// Return custom pEp titleTextAttributes
    static private func titleTextAttributes() -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: UIColor.black]
    }

    // MARK: - iOS 13

    /// Default appearance for navigation bars (iOS 13 and upwards).
    @available(iOS 13, *)
    static private func navigationBarAppearanceDefault(color: UIColor) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        let titleTextAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: color,
                                                                   .baselineOffset: 2]
        let buttonsAttributes: [NSAttributedString.Key : Any] = [.foregroundColor: UIColor.pEpGreen]
        appearance.buttonAppearance.normal.titleTextAttributes = buttonsAttributes
        appearance.titleTextAttributes = titleTextAttributes
        appearance.largeTitleTextAttributes = titleTextAttributes
        appearance.doneButtonAppearance.normal.titleTextAttributes = buttonsAttributes
        let chevronLeftImg = UIImage(named: "chevron-icon-left")?
            .resizeImage(targetSize: CGSize(width: 15, height: 25))
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
        let newTintImage = UIImage(named: "white-chevron-icon-left")!.withRenderingMode(.alwaysOriginal)
        navigationBarAppearance.setBackIndicatorImage(newTintImage, transitionMaskImage: newTintImage)
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

// MARK: - WIP (resizeImage is necessary for pEp-share app shared extension)

extension UIImage {

    /// Method that resize the image that invokes and returns a new one.
    /// - Parameter targetSize: The desired size of the image.
    public func resizeImage(targetSize: CGSize) -> UIImage? {

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio,
                             height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,
                             height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out
        // and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width,
                          height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

}
