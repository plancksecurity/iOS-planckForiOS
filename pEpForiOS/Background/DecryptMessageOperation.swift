//
//  DecryptMessageOperation.swift
//  pEp
//
//  Created by Andreas Buff on 11.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol DecryptMessageOperationDelegate: class {

    /// Called in case a DecryptionResult can be provided.
    ///
    /// - Parameters:
    ///   - sender: reporting decrypt operation
    ///   - didDecryptMessageWithResult: all information we got from the Engine, decrypting
    ///                                  the message.
    func decryptMessageOperation(sender: DecryptMessageOperation,
                                  didDecryptMessageWithResult result:
        DecryptMessageOperation.DecryptionResult)

    /// Called for any error cases in which no DecryptionResult can be provided.
    ///
    /// - Parameters:
    ///   - sender: reporting decrypt operation
    ///   - error: occured error
    func decryptMessageOperation(sender: DecryptMessageOperation, failed error: Error)
}

/// Decrypts one message.
class DecryptMessageOperation: Operation {
    struct DecryptionResult {
        /// The original message that might have been modified by the Engine
        let givenMessage: NSDictionary
        /// The decrypted message returned by the engine
        let pEpDecryptedMessage: NSDictionary?
        /// Flags returned by the engine
        let flags: PEP_decrypt_flags
        /// Rating returned by the engine
        let rating: PEP_rating
        /// Keys returned by the Engine
        let keys: NSArray?
    }

    weak var delegate: DecryptMessageOperationDelegate?

    let messageToDecrypt: PEPMessageDict
    let flags: PEP_decrypt_flags

    private let logger = Logger(category: Logger.backend)

    init(messageToDecrypt: PEPMessageDict, flags: PEP_decrypt_flags,
         delegate: DecryptMessageOperationDelegate) {
        self.messageToDecrypt = messageToDecrypt
        self.flags = flags
        self.delegate = delegate
    }

    override func main() {
        if isCancelled {
            return
        }
        process()
    }

    private func process() {
//        Log.info(component: #function, content: "Will decrypt \(messageToDecrypt)")
        let inOutMessage = messageToDecrypt.mutableDictionary()
        var inOutFlags = flags
        var keys: NSArray?
        var rating = PEP_rating_undefined
        var pEpDecryptedMessage: NSDictionary? = nil

        do {
            pEpDecryptedMessage = try PEPSession().decryptMessageDict(inOutMessage,
                                                                      flags: &inOutFlags,
                                                                      rating: &rating,
                                                                      extraKeys: &keys,
                                                                      status: nil)
                as NSDictionary

            let result = DecryptionResult(givenMessage: inOutMessage,
                                          pEpDecryptedMessage: pEpDecryptedMessage,
                                          flags: inOutFlags,
                                          rating: rating,
                                          keys: keys)
            delegate?.decryptMessageOperation(sender: self, didDecryptMessageWithResult: result)

        } catch {
            logger.errorAndCrash("Error decrypting")
            delegate?.decryptMessageOperation(sender: self, failed: error)
        }
    }
}
