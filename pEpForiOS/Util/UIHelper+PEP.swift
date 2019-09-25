//
//  UIHelper+PEP.swift
//  pEp
//
//  Created by Alejandro Gelos on 25/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

// MARK: - UIHelper+PEP

extension UIHelper {
    /// Indicate if the viewController is a pEpModal ViewController.
    /// pEpModals are TutorialWizardViewController and LoginViewController
    ///
    /// - Parameter viewController: viewController to check if is a pEpModel
    /// - Returns: true if is a pEpModal and false if not.
    static func isPEPModal(viewController: UIViewController?) -> Bool {
        guard let viewController = viewController else {
            return false
        }

        if viewController is TutorialWizardViewController {
            return true
        }

        if let nav = viewController as? UINavigationController,
            nav.rootViewController is LoginViewController {
            return true
        }

        return false
    }

    /**
     Get the UIColor for the background image of a send button for an (abstract) pEp color.
     */
    static func sendButtonBackgroundColorFromPepColor(_ pepColor: PEPColor) -> UIColor? {
        switch pepColor {
        case .green:
            return UIColor.green
        case .yellow:
            return UIColor.yellow
        case PEPColor.red:
            return UIColor.red
        default:
            return nil
        }
    }

    /**
     Cell background color in trustwords cell for indicating the rating of a contact.
     */
    static func trustWordsCellBackgroundColorFromPepColor(_ pepColor: PEPColor) -> UIColor? {
        return sendButtonBackgroundColorFromPepColor(pepColor)
    }

    /**
     Get the UIColor for an identity (in a text field or label) for an (abstract) pEp color.
     This might, or might not, be the same,
     as `sendButtonBackgroundColorFromPepColor:PrivacyColor`.
     */
    static func textBackgroundUIColorFromPrivacyColor(_ pepColor: PEPColor) -> UIColor? {
        switch pepColor {
        case .green:
            return UIColor.green
        case .yellow:
            return UIColor.yellow
        case PEPColor.red:
            return UIColor.red
        default:
            return nil
        }
    }
}
