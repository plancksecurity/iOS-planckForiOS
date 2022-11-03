//
//  FakeAccountData.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.08.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

private typealias SettingsDict = [String:Any]

class FakeAccountData {
    func setupDeployableAccountData() {
        let url = Bundle.main.url(forResource: "test_MDM_1", withExtension: "plist")!
        let plistDict = NSDictionary.init(contentsOf: url)!
        UserDefaults.standard.set(plistDict, forKey: MDMDeployment.keyMDM)
    }
}
