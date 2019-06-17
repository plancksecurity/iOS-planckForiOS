//
//  SettingsCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

extension SettingsCellViewModel {
    public enum SettingType {
        case account
        case showLog
        case credits
        case defaultAccount
        case trustedServer
        case setOwnKey
        case leaveKeySyncGroup
    }
}

/// Cell for settings that are not only one on/off switch.
public class SettingsCellViewModel: ComplexSettingCellViewModelProtocol {
    var cellIdentifier = "SettingsCell"
    
    var type: SettingType
    var account: Account?
    var status: Bool?

    init(account: Account) {
        self.type = .account
        self.account = account
    }

    init(type: SettingType) {
        self.type = type
    }

    public var detail : String? {
        get {
            switch self.type {
            case .defaultAccount:
                return AppSettings.defaultAccount
            default:
                return nil
            }
        }
    }

    public var title : String? {
        get {
            switch self.type {
            case .showLog:
                return NSLocalizedString("Logging", comment: "")
            case .credits:
                return NSLocalizedString(
                    "Credits",
                    comment: "Settings: Cell (button) title to view app credits")
            case .defaultAccount:
                return NSLocalizedString("Default Account", comment:
                    "Settings: Cell (button) title to view default account setting")
            case .account:
                guard let acc = account else {
                    Log.shared.errorAndCrash("Should never be reached")
                    return nil
                }
                return acc.user.address
            case .trustedServer:
                return NSLocalizedString("Store Messages Securely",
                                         comment:
                    "Settings: Cell (button) title to view default account setting")
            case .setOwnKey:
                return NSLocalizedString("Set Own Key",
                                         comment:
                    "Settings: Cell (button) title for entering fingerprints that are made own keys")
            case .leaveKeySyncGroup:
                return NSLocalizedString("Leave Device Group",
                                comment: "Settings: Cell (button) title for leaving device group")
            }
        }
    }

    public var value : String? {
        get {
            switch self.type {
            case .showLog, .account, .credits, .trustedServer, .setOwnKey, .leaveKeySyncGroup:
                // Have no value.
                return nil
            case .defaultAccount:
                return AppSettings.defaultAccount
            }
        }
    }

    public var disclousureIndicator: Bool {
        get {
            switch type {
            case .account, .credits, .defaultAccount, .setOwnKey,. showLog, .trustedServer:
                return true
            case .leaveKeySyncGroup:
                return false
            }
        }
    }

    public func delete() {
        self.account?.delete()
    }
}
