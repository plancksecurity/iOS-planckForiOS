//
//  EditSignatureViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 19/08/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class EditSignatureViewModel {
    
    private let account: Account
    
    private weak var accountSettingsdelegate: SettingChangeDelegate?
    
    public var numberOfRows: Int {
        return 1
    }

    public var signatureInProgress: String?
    
    init(account: Account, delegate: SettingChangeDelegate? = nil) {
        self.account = account
        self.accountSettingsdelegate = delegate
    }
    
    public func signature() -> String {
        return account.signature
    }

    public func updateSignature() {
        account.signature = signatureInProgress ?? signature()
        accountSettingsdelegate?.didChange()
    }
}
