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
        case credits
        case defaultAccount
        case trustedServer
        case setOwnKey
        case extraKeys
        case contacts
    }
}

/// Cell for settings that are not only one on/off switch.
final class SettingsCellViewModel: ComplexSettingCellViewModelProtocol {
    var cellIdentifier = "SettingsCell"
    
    var type: SettingType
    var account: Account?
    var status: Bool?

    private var messageModelService: MessageModelServiceProtocol?

    init(account: Account,
         messageModelService: MessageModelServiceProtocol) {
        self.type = .account
        self.account = account
        self.messageModelService = messageModelService
    }

    init(type: SettingType) {
        self.type = type
    }

    var detail : String? {
        get {
            switch type {
            case .defaultAccount:
                return AppSettings.defaultAccount
            default:
                return nil
            }
        }
    }

    var title : String? {
        get {
            switch type {
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
            case .extraKeys:
                return NSLocalizedString("Extra Keys",
                                         comment:
                    "Settings: Cell (button) title to view Extra Keys setting")
            case .contacts:
                return NSLocalizedString("Reset trust", comment:
                    "Settings: cell (button) title to view the trust contacts option")
            }
        }
    }

    var value : String? {
        get {
            switch type {
            case .account, .credits, .trustedServer, .setOwnKey, .extraKeys, .contacts:
                // Have no value.
                return nil
            case .defaultAccount:
                return AppSettings.defaultAccount
            }
        }
    }

    func delete() {
        guard let acc = account,
            let messageModelService = messageModelService else {
                Log.shared.errorAndCrash(message: "Account lost")
                return
        }
        
        let oldAddress = acc.user.address
        acc.delete()
        acc.session.commit()

        if Account.all().count == 1,
            let account = Account.all().first {
            do {
                if try !account.isPEPSyncEnabled() {
                    messageModelService.disableKeySync()
                    AppSettings.keySyncEnabled = false
                }
            } catch {
                Log.shared.errorAndCrash("Fail to get account pEpSync state")
            }
        }

        if AppSettings.defaultAccount == oldAddress {
            let newDefaultAccount = Account.all().first
            guard let newDefaultAddress = newDefaultAccount?.user.address else {
                return
                //no more accounts, no default account
            }
            AppSettings.defaultAccount = newDefaultAddress
        }
    }
}
