//
//  PassphraseUtil.swift
//  MessageModel
//
//  Created by Andreas Buff on 30.06.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

public protocol PassphraseUtilProtocol {

    /// Handles new passphrases entered by the user.
    /// - Parameter passphrase: passphrase entered by the user. The max length is 250 code points
    /// - throws:PassphraseError.tooLong in case the length of the passphrase exceeds the maximum
    func newPassphrase(_ passphrase: String) throws

    //BUFF: rm?
//    /// After setting a passphrase here newly generated keys (creating a new account or resetting
//    /// accounts) will be setup with this passphrase.
//    ///
//    /// - Parameter passphrase: passphrase to use for generating new keys. The max length is 250 code points
//    /// - throws:PassphraseError.tooLong in case the length of the passphrase exceeds the maximum
//    func passphraseForNewKeys(_ passphrase: String) throws
}

extension PassphraseUtil {
    public enum PassphraseError: Error {
        case tooLong
    }
}

public class PassphraseUtil {
    /// Make initializable for clients of MM.
    public init() {}
}

// MARK: - PassphraseUtilProtocol

//extension PassphraseUtil: PassphraseUtilProtocol {
//
//    public func newPassphrase(_ passphrase: String) throws {
//        let pEpSession = PEPSession()
//        do {
//            try pEpSession.configurePassphrase(passphrase)
//        } catch error as NSError {
//            if Error {
//                <#code#>
//            }
//        }
//    }
//
//
//}
