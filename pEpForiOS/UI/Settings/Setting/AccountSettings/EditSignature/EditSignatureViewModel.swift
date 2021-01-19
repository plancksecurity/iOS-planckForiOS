//
//  EditSignatureViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 19/08/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel


public protocol AccountSettingsDelegate: class {
    /// Informs Account Settings that something had changed.
    func didChange()
}

class EditSignatureViewModel {
    
    private let account: Account
    
    private weak var accountSettingsdelegate: AccountSettingsDelegate?
    
    public var numberOfRows: Int {
        return 1
    }
    
    init(account: Account, delegate: AccountSettingsDelegate? = nil) {
        self.account = account
        self.accountSettingsdelegate = delegate
    }
    
    public func updateSignature(newSignature: String) {
        account.signature = newSignature
        accountSettingsdelegate?.didChange()
    }
    
    public func signature() -> String {
        return account.signature
    }
}
