//
//  ClientCertificateManagementViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol ClientCertificateManagementViewModelDelegate: class {
    /// Provides the client certificate the user selected
    /// - Parameter clientCertificate: the client certificate the user selected
    func didSelectClientCertificate(clientCertificate: ClientCertificateUtil.ClientCertificate?)
}

// MARK: - Row

extension ClientCertificateManagementViewModel {
    struct Row {
        var name: String {
            return clientCertificate.userReadableLabel
        }
        fileprivate let clientCertificate: ClientCertificateUtil.ClientCertificate
    }
}

class ClientCertificateManagementViewModel {
    private let clientCertificateUtil: ClientCertificateUtil
    public private(set) var rows = [Row]()
    weak public var delegate: ClientCertificateManagementViewModelDelegate?

    public init(clientCertificateUtil: ClientCertificateUtil = ClientCertificateUtil(),
                delegate: ClientCertificateManagementViewModelDelegate? = nil) {
        self.clientCertificateUtil = clientCertificateUtil
        self.delegate = delegate
        setup()
    }

    public func handleDidSelect(rowAt indexPath: IndexPath) {
        delegate?.didSelectClientCertificate(clientCertificate: rows[indexPath.row].clientCertificate)
    }
}

// MARK: - Private

extension ClientCertificateManagementViewModel {

    private func setup() {
        rows = clientCertificateUtil.listCertificates().map { Row(clientCertificate: $0) }
    }
}
