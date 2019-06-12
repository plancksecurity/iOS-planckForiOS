//
//  ViewController+Storyboard.swift
//  pEp
//
//  Created by Alejandro Gelos on 07/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIViewController {

    // Not using static as it wont be possible to override to provide custom storyboardID then
    class var storyboardID : String {
        return "\(self)"
    }

    static func instantiate(fromAppStoryboard appStoryboard: StoryboardUtils.AppStoryboard) -> Self? {
        guard let viewController = appStoryboard.viewController(viewControllerClass: self) else {
            Log.shared.errorAndCrash("%@",
                        AppError.Storyboard.failToInitViewController.localizedDescription)
            return nil
        }
        return viewController
    }
}
