//
//  AccountVerifierProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 16.06.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

public protocol AccountVerifierProtocol {
    typealias AccountVerifierCallback = (_ error: Error?) -> ()

    func verify(address: String,
                userName: String,
                password: String,
                loginName: String,
                serverIMAP: String,
                portIMAP: UInt16,
                serverSMTP: String,
                portSMTP: UInt16,
                verifiedCallback: @escaping AccountVerifierCallback)
}
