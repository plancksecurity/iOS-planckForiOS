//
//  AppSettingsProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol AppSettingsProtocol {
    var shouldReinitializePepOnNextStartup: Bool { get set }
    var unencryptedSubjectEnabled: Bool { get set }
    var threadedViewEnabled: Bool { get set }
    var passiveMode: Bool { get set }
    var defaultAccount: String? { get set }
}
