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

    /// After setting a passphrase here newly generated keys (creating a new account or resetting
    /// accounts) will be setup with this passphrase.
    ///
    /// - Parameter passphrase: passphrase to use for generating new keys. The max length is 250
    ///                         code points
    /// - throws:PassphraseError.tooLong in case the length of the passphrase exceeds the maximum
    func newPassphraseForNewKeys(_ passphrase: String) throws

    /// If a passphrase for new keys is currently configured, it will be removed. Else calling this
    /// has no effect.
    func stopUsingPassphraseForNewKeys()


    /// Whether or not the user has setup a passphrase to use for generating new keys.
    var isPassphraseForNewKeysEnabled: Bool { get }
}

extension PassphraseUtil {
    public enum PassphraseError: Error {
        /// The length of the passphrase exceeds the maximum length allowed.
        case tooLong
    }
}

public class PassphraseUtil {
    /// Make initializable for clients of MM.
    public init() {}

    /// Configures the adapter to use the stored passphrase for new keys if any.
    /// If ther is no passphrase for new keys stored, it's a NOP.
    /// - note: Must be called on every application startup.
    func configureAdapterWithPassphraseForNewKeys() {
        guard let passphrase = KeyChain.passphraseForNewKeys else {
            // No passphrase is setup (stored) for new keys.
            // Nothing to do.
            return
        }
        do {
            try PEPObjCAdapter.configurePassphrase(forNewKeys: passphrase)
        } catch {
             Log.shared.errorAndCrash("Looks like we have stored an invalid passphrase. Validity MUST be checked _before_ storing it, so we have a bug here.")
        }
    }
}

// MARK: - PassphraseUtilProtocol

extension PassphraseUtil: PassphraseUtilProtocol {

    public func newPassphrase(_ passphrase: String) throws {
        let pEpSession = PEPSession()
        do {
            try pEpSession.configurePassphrase(passphrase)
        } catch let error as NSError {
            if error.domain == PEPObjCAdapterErrorDomain {
                switch error.code {
                case PEPAdapterError.passphraseTooLong.rawValue:
                    throw PassphraseError.tooLong
                default:
                    Log.shared.errorAndCrash("This should never happen :-/. Error: %@", error)
                    break
                }
            }
        }
    }

    public func newPassphraseForNewKeys(_ passphrase: String) throws {
        do {
            try PEPObjCAdapter.configurePassphrase(forNewKeys: passphrase)
            KeyChain.storePassphraseForNewKeys(passphrase)
        } catch let error as NSError {
            if error.domain == PEPObjCAdapterErrorDomain {
                switch error.code {
                case PEPAdapterError.passphraseTooLong.rawValue:
                    throw PassphraseError.tooLong
                default:
                    Log.shared.errorAndCrash("This should never happen :-/. Error: %@", error)
                    break
                }
            }
        }
    }

    public func stopUsingPassphraseForNewKeys() {
        do {
            try PEPObjCAdapter.configurePassphrase(forNewKeys: nil)
            KeyChain.deletePassphraseForNewKeys()
        } catch let error as NSError {
            Log.shared.errorAndCrash("Uups. We did not expect anthing thrown here but got error: %@",
                                     error)
        }
    }

    public var isPassphraseForNewKeysEnabled: Bool {
        return KeyChain.passphraseForNewKeys == nil ? false : true
    }
}
