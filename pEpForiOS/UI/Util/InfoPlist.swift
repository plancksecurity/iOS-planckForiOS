//
//  InfoPlist.swift
//  pEp
//
//  Created by Andreas Buff on 17.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

struct InfoPlist {
    static private var infoDictMainBundle: [String:Any]? {
        return Bundle.main.infoDictionary
    }

    static public func mainBundleVersion() -> String? {
        guard let version = mainBundleInfoDictValue(forKey: "CFBundleVersion") as? String else {
            return nil
        }
        return version
    }
    
    static public func mainBundleShortVersion() -> String? {
        guard let version = mainBundleInfoDictValue(forKey: "CFBundleShortVersionString") as? String else {
            return nil
        }
        return version
    }

    static private func mainBundleInfoDictValue(forKey key: String) -> Any? {
        guard let infoDict = infoDictMainBundle else {
            Log.shared.errorAndCrash("No info dict")
            return nil
        }
        return infoDict[key]
    }
}
