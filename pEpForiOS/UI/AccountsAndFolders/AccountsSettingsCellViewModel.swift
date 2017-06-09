//
//  AccountsSettingsCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class AccountsSettingsCellViewModel {

    var account: Account?
    var type: SettingsCell?
    var status: Bool?

    init(account: Account) {
        self.account = account
    }

    init(type: SettingsCell) {
        self.type = type
        if type == .organizedByThread {
            status = false
        }
    }

    public var title : String? {
        get {
            if let acc = account {
                return acc.user.address
            } else if let type = self.type {
                switch type {
                case .showLog:
                    break
                case .organizedByThread:
                    break
                }
            }
            return nil
        }
    }
}
