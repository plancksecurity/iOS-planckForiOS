//
//  AccountTypeSelectorViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public enum AccountTypeProvider {
    case gmail
    case other
    case certificate
    var isOauth: Bool {
        return self != .other
    }
}

class AccountTypeSelectorViewModel {

    /// list of providers to show
    var providers = [AccountTypeProvider]()

    init() {
        providers.append(.gmail)
        providers.append(.certificate)
        providers.append(.other)
    }

    var count: Int {
        get {
            return providers.count
        }
    }

    subscript(index: Int) -> AccountTypeProvider {
        return providers[index]
    }

    /// returns the text corresponding to the provider
    /// - Parameter provider: provider to obtain it's text
    func fileNameOrText(provider: AccountTypeProvider) -> String {
        switch provider {
        case .gmail:
            return "asset-Google"
        case .other:
            return NSLocalizedString("Other", comment: "Other provider key")
        case .certificate:
            return NSLocalizedString("""
            Client
            Certificate
            """, comment: "client certificate provider key")
            
        }
    }

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }
}
