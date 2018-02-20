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
                    return NSLocalizedString("Logging", comment: "")
                case .organizedByThread:
                    return NSLocalizedString("Enable Threading", comment: "")
                case .credits:
                    return NSLocalizedString("Credits", comment:
                        "AccountsSettings: Cell (button) title to view app credits")
                case .syncTrash:
                    return NSLocalizedString("Sync Trash Folder", comment:
                        "AccountsSettings: Cell (button) title to view syncing trashed setting")
                }
            }
            return nil
        }
    }

    public var value : String? {
        get {
           if let type = self.type {
                switch type {
                case .showLog:
                    return nil
                case .organizedByThread:
                    return nil // Feature unimplemented
                case .credits:
                    return nil
                case .syncTrash:
                    return AppSettings().shouldSyncImapTrashWithServer
                    ? NSLocalizedString("On", comment: "On/Off status of synTrash setting")
                    : NSLocalizedString("Off", comment: "On/Off status of synTrash setting")
                }
            }
            return nil
        }
    }

    public func delete() {
        self.account?.delete()
    }
}
