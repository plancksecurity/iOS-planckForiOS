//
//  FakeMDM.swift
//  planckForiOS
//
//  Created by Martin Brude on 29/8/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

class FakeMDM {

    // Setup a fake MDM bunch of settings
    func setupDeployableAccountData() {
#if DEBUG
        if let url = Bundle.main.url(forResource: "MDM_fake_PASSWORD_021", withExtension: "plist"),
           let plistDict = NSDictionary.init(contentsOf: url) {
            UserDefaults.standard.set(plistDict, forKey: MDMDeployment.keyMDM)
            MDMSettingsUtil().configure { result in }
        }
#endif
    }
}
