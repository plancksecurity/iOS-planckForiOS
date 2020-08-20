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
    
    public var numberOfRows: Int {
        return 1
    }
    
    init(account: Account) {
        self.account = account
    }
    
    public func updateSignature(newSignature: String) {
        AppSettings.shared.storeSignatureForAddress(address: account.user.address,signature: newSignature)
    }
    
    public func actualSignature() -> String {
        return AppSettings.shared.loadSignatureForAddress(address: account.user.address)
    }
}
