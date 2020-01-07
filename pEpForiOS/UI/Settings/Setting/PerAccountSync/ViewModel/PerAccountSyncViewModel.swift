//
//  PerAccountSyncViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 07/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

class PerAccountSyncViewModel {
    
    var accounts = Account.all()

    subscript(index: Int) -> String {
        get {
            return self.accounts[index].user.userNameOrAddress
        }
    }

    var count : Int {
        return self.accounts.count
    }

    func syncStatus(index: Int) -> Bool {
        return false
    }
}
