//
//  EnableKeySyncViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 19/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

struct EnableKeySyncViewModel: SwitchSettingCellViewModelProtocol  {

    // MARK: - SwitchSettingCellViewModelProtocol

    var cellIdentifier = "switchOptionCell"
    private let messageModelService: MessageModelServiceProtocol

    private(set) var title = NSLocalizedString("Key Sync Enable",
                                               comment: "enable key sync with other devices in the group")
    
    init(_ messageModelService: MessageModelServiceProtocol) {
        self.messageModelService = messageModelService
    }

    func setSwitch(value: Bool) {
        switch value {
        case true:
            messageModelService.enableKeySync()
        case false:
            messageModelService.disableKeySync()
        }
        AppSettings.keySyncEnabled = value
    }

    func switchValue() -> Bool {
        return AppSettings.keySyncEnabled
    }
}
