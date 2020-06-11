//
//  BaseViewController.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import MessageModel

class BaseViewController: UIViewController {
    
    /// Indicates when the navigation bar tint color must be white.
    /// As in iOS 13 the property to set that color changed, we use this flag to set it properly.
    /// Use it if for an specific view, the navigation bar tint color must be white.
    /// To use is, set it to true before the segue is performed.
    public var navigationBarTintColorWhite : Bool = false {
        didSet {
            if navigationBarTintColorWhite {
                guard let navController = navigationController else {
                    // This is a valid case. Not all ViewControllers are in a NavigationController
                    return
                }
                navController.navigationBar.barTintColor = .white
                navController.navigationBar.tintColor = .white
                UINavigationBar.appearance().tintColor = .white
            } else {
                //Keep the values of navigation navigationBar's tintColor and barTintColor to support the first loading.
                UINavigationBar.appearance().tintColor = .pEpGreen
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationBarTintColorWhite = false
    }
}
