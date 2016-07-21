//
//  DetailTrustWordsViewCell.swift
//  pEpForiOS
//
//  Created by ana on 20/7/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class DetailTrustWordsViewCell: UITabBarController {


    var message: Message?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.toolbar.hidden = true
        //let destinationViewControllers = self.tabBarController?.viewControllers
        let destinationViewControllers2 = self.viewControllers![0] as! VerboseTrustWordViewController
        destinationViewControllers2.message = self.message
    }

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {

    }


}
