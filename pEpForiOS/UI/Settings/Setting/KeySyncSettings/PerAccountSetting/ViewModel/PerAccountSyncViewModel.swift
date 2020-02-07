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
            return self.accounts[index].user.address
        }
    }

    var count : Int {
        return self.accounts.count
    }

    func syncStatus(index: Int) -> Bool {
        do {
            return try accounts[index].isKeySyncEnabled()
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
        return false
    }

    func updateKeySyncStatus(inAccount index: Int, to value: Bool) {
        do {
            try accounts[index].setKeySyncEnabled(enable: value)
        } catch {
            Log.shared.errorAndCrash(error: error)
        }

    }
}
