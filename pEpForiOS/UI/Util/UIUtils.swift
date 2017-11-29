//
//  UIUtils.swift
//  pEp
//
//  Created by Andreas Buff on 29.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

struct UIUtils {
    
    static func show(error: Error, inViewController vc: UIViewController) {
        Log.shared.error(component: #function, error: error)
        let alertView = UIAlertController(
            title: NSLocalizedString("Error", comment: "UIAlertController error title"),
            message:error.localizedDescription, preferredStyle: .alert)
        alertView.view.tintColor = .pEpGreen
        alertView.addAction(UIAlertAction(
            title: NSLocalizedString("Ok", comment: "UIAlertAction ok after error"),
            style: .default, handler: {action in
        }))
        vc.present(alertView, animated: true, completion: nil)
    }
}
