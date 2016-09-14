//
//  CustomNavigationViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/09/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class CustomNavigationViewController: UINavigationController {

    override func popViewControllerAnimated(animated: Bool) -> UIViewController? {
        if let vc = viewControllers.last {
            if vc.isKindOfClass(ComposeViewController) {
                return nil
            }
        }
        return super.popViewControllerAnimated(animated)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
