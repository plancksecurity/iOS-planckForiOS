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
    
    private weak var editableAccountSettingsdelegate: EditableAccountSettingsDelegate?
    
    public var numberOfRows: Int {
        return 1
    }
    
    init(account: Account, delegate: EditableAccountSettingsDelegate? = nil) {
        self.account = account
        self.editableAccountSettingsdelegate = delegate
    }
    
    public func updateSignature(newSignature: String) {
        account.signature = newSignature
        editableAccountSettingsdelegate?.didChange()
    }
    
    public func signature() -> String {
        return account.signature
    }
}
