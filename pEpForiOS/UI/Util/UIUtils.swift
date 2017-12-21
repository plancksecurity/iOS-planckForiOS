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
        Log.shared.errorComponent(#function, message: "Will display error to user: \(error)")
        let displayError = DisplayUserError(withError: error)
        let alertView = UIAlertController(title: displayError.title,
                                          message:displayError.errorDescription,
                                          preferredStyle: .alert)
        alertView.view.tintColor = .pEpGreen
        alertView.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:
            "Error alert positive button button"),
                                          style: .default,
                                          handler: nil))
        vc.present(alertView, animated: true, completion: nil)
    }

    static func showAlertWithOnlyPositiveButton(title: String, message: String,
                                                inViewController vc: UIViewController) {
        let alertView = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
        alertView.view.tintColor = .pEpGreen
        alertView.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment:
            "General alert positive button"),
                                          style: .default,
                                          handler: nil))
        vc.present(alertView, animated: true, completion: nil)
    }
}
