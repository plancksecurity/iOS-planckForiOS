//
//  ActionCellViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 17/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//
import Foundation
import MessageModel
import pEpIOSToolbox

extension SettingsActionCellViewModel {
    enum ActionCellType {
        case keySyncSetting
        case resetAllIdentities
        case resetTrust
    }
}

/// Cell for settings that are not only one on/off switch.
final class SettingsActionCellViewModel: SettingsActionCellViewModelProtocol {
    var cellIdentifier = "SettingsActionCell"

    var type: ActionCellType

    init(type: ActionCellType) {
        self.type = type
    }

    var title: String {
        get {
            switch type {
            case .keySyncSetting:
                switch keySyncSettingCellState {
                case .enablekeySync:
                    return NSLocalizedString("Enable p≡p Sync",
                                             comment: "enable p≡p Sync with other devices in the group")
                case .disablekeySync:
                    return NSLocalizedString("Disable p≡p Sync",
                                             comment: "enable p≡p Sync with other devices in the group")
                case .leaveDeviceGroup:
                    return NSLocalizedString("Leave Device Group",
                                             comment: "Settings: Cell (button) title for leaving device group")
                case .none:
                    Log.shared.errorAndCrash("Invalid state")
                    // Return nonsense
                    return ""
                }
            case .resetAllIdentities:
                return NSLocalizedString("Reset All Identities",
                                         comment: "Settings: Cell (button) title for reset all identities")
            case .resetTrust:
                return NSLocalizedString("Reset", comment:
                    "Settings: cell (button) title to view the trust contacts option")
            }
        }
    }

    var titleColor: UIColor? {
        get {
            switch type {
            case .keySyncSetting:
                switch keySyncSettingCellState {
                case .none:
                    Log.shared.errorAndCrash("Invalid state")
                    return nil
                case .disablekeySync, .enablekeySync:
                    return nil
                case .leaveDeviceGroup:
                    return .pEpRed
                }
            default:
                return .pEpRed
            }
        }
    }
}

// MARK: - Private

extension SettingsActionCellViewModel {

    enum KeySyncSettingCellState {
        case none
        case enablekeySync
        case disablekeySync
        case leaveDeviceGroup
    }

    var keySyncSettingCellState: KeySyncSettingCellState {
        if type != .keySyncSetting {
            // We are called on a cell vm that is not related to keySync
            return .none
        }
        let grouped = KeySyncUtil.isInDeviceGroup
        let keySyncEnabled = KeySyncUtil.isKeySyncEnabled
        if !grouped && keySyncEnabled {
            return .disablekeySync
        } else if !grouped && !keySyncEnabled {
            return .enablekeySync
        } else if grouped {
            return .leaveDeviceGroup
        } else {
            Log.shared.errorAndCrash("Invalid state")
            // Retunr nonsense to avoid Optional
            return .disablekeySync
        }
    }

    func handleKeySyncSettingCellPressed() { //BUFF: change after adapter changes are in
        switch keySyncSettingCellState {
        case .enablekeySync:
            KeySyncUtil.enableKeySync()
        case .disablekeySync:
            KeySyncUtil.disableKeySync()
        case .leaveDeviceGroup:
            do {
                try KeySyncUtil.leaveDeviceGroup()
            } catch {
                Log.shared.errorAndCrash(error: error)
            }
        case .none:
            Log.shared.errorAndCrash("Invalid state")
            return
        }
    }
}

