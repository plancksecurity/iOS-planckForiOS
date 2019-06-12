//
//  StoryBoardUtils.swift
//  pEp
//
//  Created by Alejandro Gelos on 07/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

struct StoryboardUtils {
    enum AppStoryboard: String {
        case main = "Main"
        case thread = "Thread"
        case reusable = "Reusable"
        case settings = "Settings"
        case handShake = "HandShake"
        case folderViwes = "FolderViwes"
        
        var instance: UIStoryboard {
            return UIStoryboard(name: rawValue, bundle: .main)
        }

        func viewController<T: UIViewController>(viewControllerClass: T.Type) -> T? {
            let storyboardID = viewControllerClass.storyboardID
            guard let scene = instance.instantiateViewController(withIdentifier: storyboardID) as? T
                else {
                    Log.shared.errorAndCrash(
                        "%@", AppError.Storyboard.failToInitViewController.localizedDescription)
                    return nil
            }
            return scene
        }

        func initialViewController() -> UIViewController? {
            return instance.instantiateInitialViewController()
        }
    }
}
