//
//  InfoPlist.swift
//  pEp
//
//  Created by Andreas Buff on 17.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

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
    
    static public func userManualURL() -> String? {
        guard let userManualURL = mainBundleInfoDictValue(forKey: "USER_MANUAL_URL") as? String else {
            return nil
        }
        guard let shortVersion = mainBundleShortVersion() else {
            Log.shared.errorAndCrash("Missing app version")
            return "3.1.5"
        }
        let version = shortVersion.replacingOccurrences(of: ".", with: "-")
        return userManualURL.replaceFirstOccurrence(of: "version", with: version)
    }
    
    static public func termsAndConditionsURL() -> String? {
        guard let termsAndConditionsURL = mainBundleInfoDictValue(forKey: "TERMS_AND_CONDITIONS_URL") as? String else {
            return nil
        }
        return termsAndConditionsURL
    }

    static private func mainBundleInfoDictValue(forKey key: String) -> Any? {
        guard let infoDict = infoDictMainBundle else {
            Log.shared.errorAndCrash("No info dict")
            return nil
        }
        return infoDict[key]
    }
}
