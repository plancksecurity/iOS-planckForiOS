//
//  PEPUtil.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public class PEPUtil {
    private static let homeUrl = NSURL(fileURLWithPath:
                                      NSProcessInfo.processInfo().environment["HOME"]!)
    private static let pEpManagementDbUrl =
                                         homeUrl.URLByAppendingPathComponent(".pEp_management.db")
    private static let gnupgUrl = homeUrl.URLByAppendingPathComponent(".gnupg")
    private static let gnupgSecringUrl = gnupgUrl.URLByAppendingPathComponent("secring.gpg")
    private static let gnupgPubringUrl = gnupgUrl.URLByAppendingPathComponent("pubring.gpg")
    
    // Provide filepath URLs as public dictionary.
    public static let pEpUrls: [String:NSURL] = [
                      "home": homeUrl,
                      "pEpManagementDb": pEpManagementDbUrl,
                      "gnupg": gnupgUrl,
                      "gnupgSecring": gnupgSecringUrl,
                      "gnupgPubring": gnupgPubringUrl]
}