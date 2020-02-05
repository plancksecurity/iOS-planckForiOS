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

    let cellIdentifier = "switchOptionCell"
    var delegate: keySyncActionsProtocol?

    private(set) var title = NSLocalizedString("p≡p Sync", comment: "pep sync title")

    func setSwitch(value: Bool) {
        delegate?.updateSyncStatus(to: value)
    }

    var switchValue: Bool {
        let keySyncEnabled = KeySyncUtil.isKeySyncEnabled
        return keySyncEnabled
    }

    var isGrouped: Bool {
        return KeySyncUtil.isInDeviceGroup
    }
}

protocol keySyncActionsProtocol {
    func updateSyncStatus(to: Bool)
}
