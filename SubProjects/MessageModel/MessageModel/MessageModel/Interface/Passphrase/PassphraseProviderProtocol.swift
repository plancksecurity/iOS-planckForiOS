//
//  PassphraseProviderDelegate.swift
//  MessageModel
//
//  Created by Andreas Buff on 08.07.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

/// Someone on client side that can provide us with passphrases in cases we need one.
public protocol PassphraseProviderProtocol: AnyObject {

    /// We need a passphrase to do our job. If you can, provide it as the input parameter of the
    /// completion block, pass `nil` otherwize.
    /// - Parameter completion: call this to return the passphrase or `nil` if you can not provide
    ///                         it for some reason.
    func showEnterPassphrase(triggeredWhilePEPSync: Bool,
                             completion: @escaping (String?)->Void)

    /// The known passphrases do not work, but we need a valid passphrase to do our job. If you can,
    /// provide it as the input parameter of the completion block, otherwize pass `nil`.
    /// - Parameter completion: call this to return the passphrase or `nil` if you can not provide
    ///                         it for some reason.
    func showWrongPassphrase(completion: @escaping (String?)->Void)

    /// We received an invalid passphrase, it's too long.
    /// We need a valid passphrase to do our job. If you can, provide it as the input parameter of
    /// the completion block, pass `nil`there otherwize.
    /// - Parameter completion: call this to return the passphrase or `nil` if you can not provide
    ///                         it for some reason.
    func showPassphraseTooLong(completion: @escaping (String?)->Void)
}
