//
//  LoginViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 26/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class LoginViewModel {

    func handleFirstLogin() -> Bool {
        return Account.all().isEmpty
    }

    func login(account: String, password: String) {

    }
}
