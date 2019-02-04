//
//  SettingsCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpUtilities

extension SettingsCellViewModel {
    public enum SettingType {
        case account
        case showLog
        case credits
        case defaultAccount
        case trustedServer
        case setOwnKey
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
                    Logger.frontendLogger.errorAndCrash("Should never be reached")
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
            }
        }
    }

    public var value : String? {
        get {
            switch self.type {
            case .showLog, .account, .credits, .trustedServer, .setOwnKey:
                // Have no value.
                return nil
            case .defaultAccount:
                return AppSettings.defaultAccount
            }
        }
    }

    public func delete() {
        self.account?.delete()
    }
}
