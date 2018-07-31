//
//  SettingsSwichtViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 20/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol SettingSwitchProtocol {
    var title: String { get set }
    var switchValue: Bool { get set }
    func switchAction(value: Bool)
}

protocol SettingsCellViewModel {
    var type : SettingType { get set }
    var settingCellType : AccountSettingsCellType { get set }
    var settingsDelegate: SettingsUpdated? { get set }
}
