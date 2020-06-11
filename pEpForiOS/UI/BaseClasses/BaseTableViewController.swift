//
//  BaseTableViewController.swift
//  pEpForiOS
//
//  Created by buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox
import MessageModel

class BaseTableViewController: UITableViewController {

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
                UINavigationBar.appearance().tintColor = .pEpGreen
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.title = title
        BaseTableViewController.setupCommonSettings(tableView: tableView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationBarTintColorWhite = false
    }
}
