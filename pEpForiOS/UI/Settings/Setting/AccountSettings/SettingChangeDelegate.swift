//
//  SettingChangeDelegate.swift
//  pEp
//
//  Created by Martín Brude on 19/1/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol SettingChangeDelegate: AnyObject {
    /// Informs Account Settings that something had changed.
    func didChange()
}
