//
//  AdapterWrapper.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 16.07.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

/// Wraps UI calls into the adapter.
///
/// UI code cannot access adapter methods directly, since the adapter may
/// trigger passphrase UI and wait for an answer, which leads to deadlocks.
///
/// For that reason, the UI must not use `PEPSession` directly, but instead
/// use the methods from this class with a completion block.
///
/// The adapter will be called on a background queue and invoke the
/// completion block on the main queue with the result.
public class AdapterWrapper {
    // TODO: Don't publish CdIdentity
    public static func pEpColor(cdIdentity: CdIdentity,
                                completion: @escaping (_ error: Error?, _ color: PEPColor?) -> Void) {
        let pepC = cdIdentity.pEpIdentity()
        queue.async {
            let session = PEPSession()
            do {
                let rating = try session.rating(for: pepC).pEpRating
                let color = session.color(from: rating)
                DispatchQueue.main.async {
                    completion(nil, color)
                }
            } catch let error as NSError {
                completion(error, nil)
            }
        }
    }

    public static func pEpColor(pEpRating: PEPRating?) -> PEPColor {
        if let rating = pEpRating {
            return PEPSession().color(from: rating)
        } else {
            return PEPColor.noColor
        }
    }

    public static func reEvaluateMessage(_ message: PEPMessage,
                                         xKeyList: [String]?,
                                         completion: @escaping (_ error: Error?, _ status: PEPStatus?, _ rating: PEPRating?) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                var status: PEPStatus = .unknownError
                var rating: PEPRating = .undefined
                try session.reEvaluateMessage(message,
                                              xKeyList: xKeyList,
                                              rating: &rating,
                                              status: &status)
                completion(nil, status, rating)
            } catch {
                completion(error, nil, nil)
            }
        }
    }

    public static func outgoingRating(for theMessage: PEPMessage,
                                      errorHandler: @escaping (_ error: Error) -> Void,
                                      completion: @escaping (_ rating: PEPRating) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let rating = try session.outgoingRating(for: theMessage).pEpRating
                completion(rating)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func outgoingRatingPreview(for theMessage: PEPMessage,
                                             errorHandler: @escaping (_ error: Error) -> Void,
                                             completion: @escaping (_ rating: PEPRating) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let rating = try session.outgoingRatingPreview(for: theMessage).pEpRating
                completion(rating)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func rating(for identity: PEPIdentity,
                              errorHandler: @escaping (_ error: Error) -> Void,
                              completion: @escaping (_ rating: PEPRating) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let rating = try session.rating(for: identity).pEpRating
                completion(rating)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func trustwords(forFingerprint fingerprint: String,
                                  languageID: String,
                                  shortened: Bool,
                                  errorHandler: @escaping (_ error: Error) -> Void,
                                  completion: @escaping (_ trustwords: [String]) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let trustwords = try session.trustwords(forFingerprint: fingerprint,
                                                        languageID: languageID,
                                                        shortened: shortened)
                completion(trustwords)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func update(_ identity: PEPIdentity,
                              errorHandler: @escaping (_ error: Error) -> Void,
                              completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.update(identity)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func trustPersonalKey(_ identity: PEPIdentity,
                                        errorHandler: @escaping (_ error: Error) -> Void,
                                        completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.trustPersonalKey(identity)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func keyMistrusted(_ identity: PEPIdentity,
                                     errorHandler: @escaping (_ error: Error) -> Void,
                                     completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.keyMistrusted(identity)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func keyResetTrust(_ identity: PEPIdentity,
                                     errorHandler: @escaping (_ error: Error) -> Void,
                                     completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.keyMistrusted(identity)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func importKey(_ keydata: String,
                                 errorHandler: @escaping (_ error: Error) -> Void,
                                 completion: @escaping ([PEPIdentity]) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let identities = try session.importKey(keydata)
                completion(identities)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func getLog(errorHandler: @escaping (_ error: Error) -> Void,
                              completion: @escaping (String) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let logString = try session.getLog()
                completion(logString)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func getTrustwordsIdentity1(_ identity1: PEPIdentity,
                                              identity2: PEPIdentity,
                                              language: String?,
                                              full: Bool,
                                              errorHandler: @escaping (_ error: Error) -> Void,
                                              completion: @escaping (String) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let trustwordsString = try session.getTrustwordsIdentity1(identity1,
                                                                          identity2: identity2,
                                                                          language: language,
                                                                          full: full)
                completion(trustwordsString)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func getTrustwordsFpr1(_ fpr1: String,
                                         fpr2: String,
                                         language: String?,
                                         full: Bool,
                                         errorHandler: @escaping (_ error: Error) -> Void,
                                         completion: @escaping (String) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let trustwordsString = try session.getTrustwordsFpr1(fpr1,
                                                                     fpr2: fpr2,
                                                                     language: language,
                                                                     full: full)
                completion(trustwordsString)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func languageList(errorHandler: @escaping (_ error: Error) -> Void,
                                    completion: @escaping ([PEPLanguage]) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let languages = try session.languageList()
                completion(languages)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func rating(from string: String,
                              completion: @escaping (PEPRating) -> Void) {
        queue.async {
            let session = PEPSession()
            let rating = session.rating(from: string)
            completion(rating)
        }
    }

    public static func string(from rating: PEPRating,
                              completion: @escaping (String) -> Void) {
        queue.async {
            let session = PEPSession()
            let theString = session.string(from: rating)
            completion(theString)
        }
    }

    public static func isPEPUser(_ identity: PEPIdentity,
                                 errorHandler: @escaping (_ error: Error) -> Void,
                                 completion: @escaping (Bool) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let theBool = try session.isPEPUser(identity).boolValue
                completion(theBool)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func setOwnKey(_ identity: PEPIdentity,
                                 fingerprint: String,
                                 errorHandler: @escaping (_ error: Error) -> Void,
                                 completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.setOwnKey(identity, fingerprint: fingerprint)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func configurePassiveModeEnabled(_ enabled: Bool) {
        let session = PEPSession()
        session.configurePassiveModeEnabled(enabled)
    }

    public static func setFlags(_ flags: PEPIdentityFlags,
                                for identity: PEPIdentity,
                                errorHandler: @escaping (_ error: Error) -> Void,
                                completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.setFlags(flags, for: identity)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func deliver(_ result: PEPSyncHandshakeResult,
                               identitiesSharing: [PEPIdentity]?,
                               errorHandler: @escaping (_ error: Error) -> Void,
                               completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.deliver(result, identitiesSharing: identitiesSharing)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func trustOwnKeyIdentity(_ identity: PEPIdentity,
                                           errorHandler: @escaping (_ error: Error) -> Void,
                                           completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.trustOwnKeyIdentity(identity)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func color(from rating: PEPRating) -> PEPColor {
        let session = PEPSession()
        return session.color(from: rating)
    }

    public static func keyReset(_ identity: PEPIdentity,
                                fingerprint: String?,
                                errorHandler: @escaping (_ error: Error) -> Void,
                                completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.keyReset(identity, fingerprint: fingerprint)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func leaveDeviceGroup(errorHandler: @escaping (_ error: Error) -> Void,
                                        completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.leaveDeviceGroup()
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func enableSync(_ identity: PEPIdentity,
                                  errorHandler: @escaping (_ error: Error) -> Void,
                                  completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.enableSync(for: identity)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func disableSync(_ identity: PEPIdentity,
                                   errorHandler: @escaping (_ error: Error) -> Void,
                                   completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.disableSync(for: identity)
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func queryKeySyncEnabled(_ identity: PEPIdentity,
                                           errorHandler: @escaping (_ error: Error) -> Void,
                                           completion: @escaping (Bool) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let theBool = try session.queryKeySyncEnabled(for: identity).boolValue
                completion(theBool)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func keyResetAllOwnKeysError(errorHandler: @escaping (_ error: Error) -> Void,
                                               completion: @escaping () -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                try session.keyResetAllOwnKeysError()
                completion()
            } catch {
                errorHandler(error)
            }
        }
    }

    private static let queue = DispatchQueue(label: "AdapterWrapper",
                                             qos: .userInitiated,
                                             autoreleaseFrequency: .inherit,
                                             target: nil)
}
