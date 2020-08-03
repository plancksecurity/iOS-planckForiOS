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

    static public var pEpScheme: String? {
        guard let urlTypes = mainBundleInfoDictValue(forKey: "CFBundleURLTypes") as? NSMutableArray,
            let first = urlTypes.firstObject as? NSMutableDictionary,
            let scheme = first.object(forKey: "CFBundleURLSchemes") as? NSMutableArray
        else {
            return nil
        }

        return scheme.firstObject as? String
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
