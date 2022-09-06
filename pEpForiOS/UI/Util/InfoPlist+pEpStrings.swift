//
//  InfoPlist+pEpStrings.swift
//  pEp
//
//  Created by Andreas Buff on 20.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

extension InfoPlist {
    static public func versionDisplayString() -> String? {
        guard let version = InfoPlist.mainBundleShortVersion() else {
            return nil
        }
        let build = InfoPlist.mainBundleVersion()
        let buildString =  build != nil ? ("build " + (build ?? "")) : ""
        let appVersionPrefix = NSLocalizedString("Version",
                                                 comment:
            "AccountsView: Prefix for version. Shows up like this: \"Version: 2.0.1 build 234\"")

        let managedDictionary = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")
        let mdmSettings = managedDictionary?.description ?? "- NO MDM SETTINGS -"

        return appVersionPrefix + ": " + version + " " + buildString + " \n " + mdmSettings
    }
}
