//
//  AccountTypeSelectorViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public enum Provider {
    case GMail
    case Other
}

class AccountTypeSelectorViewModel {

    /// list of providers to show
    var providers = [Provider]()

    init() {
        providers.append(.GMail)
        providers.append(.Other)
    }

    var count: Int {
        get {
            return providers.count
        }
    }

    subscript(index: Int) -> Provider {
        return providers[index]
    }

    /// returns the text corresponding to the provider
    /// - Parameter provider: provider to obtain it's text
    func fileNameOrText(provider: Provider) -> String {
        switch provider {
        case .GMail:
            return "asset-Google"
        case .Other:
            return NSLocalizedString("Other", comment: "Other provider key")
        }
    }

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }
}
