//
//  ClientCertificateManagementViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol ClientCertificateManagementViewModelDelegate {

}

// MARK: - Row

extension ClientCertificateManagementViewModel {
    struct Row {
        let name: String
    }
}

class ClientCertificateManagementViewModel {
    private let clientCertificateUtil: ClientCertificateUtil
    public private(set) var rows = [Row]()

    init(clientCertificateUtil: ClientCertificateUtil = ClientCertificateUtil()) {
        self.clientCertificateUtil = clientCertificateUtil
        setup()
    }
}

// MARK: - Private

extension ClientCertificateManagementViewModel {

    private func setup() {
        rows = clientCertificateUtil.listCertificates().map { Row(name: $0.userReadableLabel) }
    }
}
