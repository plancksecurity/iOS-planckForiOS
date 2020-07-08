//
//  PassphraseProviderDelegate.swift
//  MessageModel
//
//  Created by Andreas Buff on 08.07.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

public protocol PassphraseProviderProtocol: class {
    func showEnterPassphrase(completion:  @escaping (String?)->Void)
    func showWrongPassphrase(completion:  @escaping (String?)->Void)
    func showPassphraseTooLong(completion:  @escaping (String?)->Void)
}
