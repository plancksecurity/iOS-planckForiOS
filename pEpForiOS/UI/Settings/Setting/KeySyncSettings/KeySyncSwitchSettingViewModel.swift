//
//  KeySyncSwitchSettingViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 09/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

struct KeySyncSwitchSettingViewModel: SwitchSettingCellViewModelProtocol  {

    // MARK: - SwitchSettingCellViewModelProtocol

    var cellIdentifier = "switchOptionCell"

    private(set) var title = NSLocalizedString("p≡p Sync", comment: "pep sync title")

    func setSwitch(value: Bool) {
        let grouped = KeySyncUtil.isInDeviceGroup
        if value {
            KeySyncUtil.enableKeySync()
        } else {
            if grouped {
                do {
                    try KeySyncUtil.leaveDeviceGroup()
                } catch {
                    Log.shared.errorAndCrash(error: error)
                }
            }
            KeySyncUtil.disableKeySync()
        }
    }

    func switchValue() -> Bool {
        let keySyncEnabled = KeySyncUtil.isKeySyncEnabled
        return keySyncEnabled
    }
}

