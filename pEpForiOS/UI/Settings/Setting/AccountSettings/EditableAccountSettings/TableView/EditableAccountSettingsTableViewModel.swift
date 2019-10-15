//
//  EditableAccountSettingsTableViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

final class EditableAccountSettingsTableViewModel {
    private var headers: [String] = [NSLocalizedString("Account", comment: "Account settings"),
                               NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"),
                               NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP")]
//    weak var delegate: EditableAccountSettingsTableViewModelDelegate?

    public let svm = SecurityViewModel()

    var count: Int {
        get {
            return headers.count
        }
    }

    public struct SecurityViewModel {
        var options = Server.Transport.toArray()
        var size : Int {
            get {
                return options.count
            }
        }

        subscript(option: Int) -> String {
            get {
                return options[option].asString()
            }
        }
    }

    subscript(section: Int) -> String {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return headers[section]
        }
    }

    func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section < headers.count
    }

    func footerFor(section: Int) -> String {
        if section < footers.count {
            return footers[section]
        }
        return ""
    }
}


// MARK: - Private

extension EditableAccountSettingsTableViewModel {
    private var footers: [String] {
        return [NSLocalizedString("Performs a reset of the privacy settings saved for a communication partner. Could be needed for example if your communication partner cannot read your messages.", comment: "Footer for Account settings section 1")]
    }
}
