//
//  NavigationControllerWithAppearance.swift
//  pEp-share
//
//  Created by Dirk Zimmermann on 29.03.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class NavigationControllerWithAppearance: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Appearance.setup()
    }
}
