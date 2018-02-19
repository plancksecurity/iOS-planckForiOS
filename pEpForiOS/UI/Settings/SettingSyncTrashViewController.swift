//
//  SettingSyncTrashViewController.swift
//  pEp
//
//  Created by Andreas Buff on 19.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class SettingSyncTrashViewController: SettingBaseViewController {
    override func handleSwitchChange() {
        AppSettings().shouldImapAppendTrashMails = `switch`.isOn
    }

    override func setSwitchValue() {
        `switch`.isOn = AppSettings().shouldImapAppendTrashMails
    }
}
