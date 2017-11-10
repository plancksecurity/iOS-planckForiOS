//
//  BaseViewController.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 23.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    private var _appConfig: AppConfig?
    var appConfig: AppConfig? {
        get {
            guard _appConfig != nil else {
                Log.shared.errorAndCrash(component: #function, errorString: "No appConfig?")
                return nil
            }
            return _appConfig
        }
        set {
            _appConfig = newValue
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
}
