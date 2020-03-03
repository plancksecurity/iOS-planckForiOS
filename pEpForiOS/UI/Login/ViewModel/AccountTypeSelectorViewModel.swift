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
    case clientCertificate
    var isOauth: Bool {
        return self == .gmail
    }
}
protocol AccountTypeSelectorViewModelDelegate: class {
    func showMustImportClientCertificateAlert()
    func showClientCertificateSeletionView()
}

class AccountTypeSelectorViewModel {

    weak var delegate: AccountTypeSelectorViewModelDelegate?

    /// list of providers to show
    var providers = [AccountTypeProvider]()

    init() {
        providers.append(.gmail)
        providers.append(.clientCertificate)
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

    public func accountType(row: Int) -> AccountTypeProvider? {
        guard row < providers.count else {
            Log.shared.errorAndCrash("Index out of range")
            return nil
        }
        return providers[row]
    }

    public func checkRequirements() {
        if ClientCertificateUtil().listCertificates().count == 0 {
            delegate?.showMustImportClientCertificateAlert()
        } else {
            delegate?.showClientCertificateSeletionView()
        }
    }

    /// returns the text corresponding to the provider
    /// - Parameter provider: provider to obtain it's text
    public func fileNameOrText(provider: AccountTypeProvider) -> String {
        switch provider {
        case .gmail:
            return "asset-Google"
        case .other:
            return NSLocalizedString("Other", comment: "Other provider key")
        case .clientCertificate:
            return NSLocalizedString("""
            Client
            Certificate
            """, comment: "client certificate provider key")
        }
    }

    public func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }
}
